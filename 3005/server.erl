-module(server).
-compile(export_all).
-import(loginmanager,[start/0, logged/1]).
-import(state,[start/2]).


server(Port) -> 
  spawn(fun() -> loginmanager:start() end), %inicia o loginmanager
  WaitRoom = spawn(fun() -> waiting([], #{}, 0) end),
  register(wait, WaitRoom),
  Command = spawn(fun() -> commands() end),
  register(?MODULE,Command),
  Ranking = spawn(fun() -> ranking(#{}, #{}) end),
  register(ranking, Ranking),
  %state:start(), %inicia o state
  Room = spawn(fun() -> room([]) end),
  {ok,LSock} = gen_tcp:listen(Port,[binary, {packet, line}, {reuseaddr, true}]),
  %register(charge,Charge),
  %?MODULE ! {generate_monsters},
  acceptor(LSock,Room).

acceptor(LSock,Room) ->
  {ok,Sock} = gen_tcp:accept(LSock),
  spawn(fun() -> acceptor(LSock,Room) end),
  user(Sock,Room).

room(Sockets) ->
    receive
        {enter, Socket} ->
            io:format("user entered ~p ~n", [Socket]),
            room([Socket | Sockets]);
        {line, Data,_} ->
            io:format("received ~p~n", [Data]),
            %[Pid ! {line,Data} || Pid <- Pids],
            room(Sockets);
        {leave, Socket} ->
            io:format("user left~n", []),
            room(Sockets -- [Socket])
    end.

user(Sock, Room) ->
    receive
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            user(Sock,Room);

        {tcp, Socket, Data} ->
            StrData = binary:bin_to_list(Data),
            case StrData of
             "\\login " ++ Dados ->
             St = string:tokens(Dados, " "),
             [U | P] = St,
             case loginmanager:login(U, P, Socket) of
              {ok,_} -> gen_tcp:send(Socket,<<"ok_login\n">>),
                  Room ! {enter,Socket},

                  wait ! {enter_waiting_list, U, self()},
                  %%wait ! {game_over},
                  receive
                      {ready, GameRoom} ->
                          io:format("Estou no ready2 ~p ~n", [U]),

                          ?MODULE ! {Socket,U, GameRoom},
                          ?MODULE ! {online,add, U, GameRoom},
                          ranking ! {add_ranking, U},
                          %UpdtMons = spawn(fun() -> update_monsters(GameRoom) end),
                          Charge = spawn(fun() -> charge_energy(GameRoom) end),
                          gen_tcp:send(Socket,<<"ready\n">>),
                          userauthenticated(Sock, Room, GameRoom, Charge)
                  end;
              _ -> gen_tcp:send(Socket,<<"invalid_login\n">>)
              end;

          
          "\\create_account " ++ Dados ->
            St = string:tokens(Dados, " "),
            %debug -------
            io:format("St: ~p ~n",[St]),
            [U | P] = St,
            case loginmanager:create_account(U, P, Socket) of
              {ok,_} -> gen_tcp:send(Socket,<<"ok_create_account\n">>);
              _ -> io:format("Erro a criar conta"),
              gen_tcp:send(Socket,<<"user_exists\n">>)
            end;

    "\\close_account " ++ Dados ->
            St = string:tokens(Dados, " "),
            [U | P] = St,
            io:format("user ~p ~n", [U]),
            io:format("pass ~p ~n", [P]),
            case loginmanager:close_account(U, P, Socket) of
              ok -> 
                gen_tcp:send(Socket,<<"ok_close_account\n">>),
                wait ! {remove_level, U},
                ranking ! {remove_level, U},
                ranking ! {remove_score, U};
              _ -> gen_tcp:send(Socket,<<"user_not_exists\n">>)
            end;

            _ -> invalid
           end,
           
           user(Sock,Room);

        {tcp_closed, Socket} ->
            Username = logged(Socket),
            case loginmanager:logout(Username, Socket) of

              ok -> 
                    gen_tcp:send(Socket,<<"ok_logout\n">>),
                    io:format("a fazer logout ~p ~n",[Username]),
                    Room ! {leave,Socket};
              _ -> 
                  io:format("erro a fazer logout ~p ~n",[Username])
            end,
            Room ! {leave, self()};

        {tcp_error, Socket, _} ->
            Username = logged(Socket),
            case loginmanager:logout(Username, Socket) of

              ok -> 
                    gen_tcp:send(Socket,<<"ok_logout\n">>),
                    io:format("a fazer logout ~p ~n",[Username]),
                    Room ! {leave,Socket};
              _ -> 
                  io:format("erro a fazer logout ~p ~n",[Username])
            end,

            Room ! {leave, self()}
    end.

    userauthenticated(Sock, Room, GameRoom, Charge) ->
      receive 
       {line, Data} ->
            gen_tcp:send(Sock, Data),
            userauthenticated(Sock, Room, GameRoom, Charge);
        {tcp, Socket, Data} ->
          StrData = binary:bin_to_list(Data),
          case StrData of 

            "\\logout " ++ Dados ->
            St = string:tokens(Dados, " "),
            [U | P] = St,
            case loginmanager:logout(U, P, Socket) of
              ok -> 
                    gen_tcp:send(Socket,<<"ok_logout\n">>),
                    io:format("a fazer logout ~p ~n",[U]),
                    Room ! {leave,Sock}, 
                    user(Sock,Room);
              _ -> 
                  io:format("erro a fazer logout ~p ~n",[U]),
                  userauthenticated(Sock,Room, GameRoom, Charge)
            end;

            "\\left\n" ->
              Username = logged(Socket),
              io:format("Fez left ~n"),
              ?MODULE ! {left,Username,GameRoom, Charge},
              Room ! {line,Data,Socket},
              userauthenticated(Sock,Room, GameRoom, Charge);

            "\\right\n" ->
              Username = logged(Socket),
              io:format("Fez right ~n"),
              ?MODULE ! {right,Username,GameRoom, Charge},
              Room ! {line,Data,Socket},
              userauthenticated(Sock,Room, GameRoom, Charge);

              "\\front\n" ->
              Username = logged(Socket),
              io:format("Fez front ~n"),
              ?MODULE ! {front,Username,GameRoom, Charge},
              Room ! {line,Data,Socket},
              userauthenticated(Sock,Room, GameRoom, Charge);

            _ ->
          %Room ! {line, Data,Socket}, não é necessário?
          userauthenticated(Sock, Room,GameRoom, Charge)
        end;
        {tcp_closed, Socket} ->
            Username = logged(Socket),
            case loginmanager:logout(Username, Socket) of

              ok -> 
                    gen_tcp:send(Socket,<<"ok_logout\n">>),
                    io:format("a fazer logout ~p ~n",[Username]),
                    Room ! {leave,Socket};
              _ -> 
                  io:format("erro a fazer logout ~p ~n",[Username])
            end,
            Room ! {leave, self()};

        {tcp_error, Socket, _} ->
            Username = logged(Socket),
            case loginmanager:logout(Username, Socket) of

              ok -> 
                    gen_tcp:send(Socket,<<"ok_logout\n">>),
                    io:format("a fazer logout ~p ~n",[Username]),
                    Room ! {leave,Socket};
              _ -> 
                  io:format("erro a fazer logout ~p ~n",[Username])
            end,
            Room ! {leave, self()}
    end.

    update_monsters(GameRoom) ->
    timer:send_after(80,GameRoom,{monsters_upt,self()}),
    receive
      {repeat} ->
          update_monsters(GameRoom)
      %stop ->
      %    none
    end.

    commands() ->
      receive
        {online,add,Username, GameRoom} ->
            io:format("Entrei no commands: add ~p ~n", [Username]),
          GameRoom ! {online,add,Username},
          commands();
        {left,Username, GameRoom, Charge} ->
            io:format("Entrei no commands: left ~p ~n", [Username]),
          GameRoom ! {left,Username, Charge},
          commands();
          {right,Username, GameRoom, Charge} ->
            io:format("Entrei no commands: right ~p ~n", [Username]),
              GameRoom ! {right,Username, Charge},
              commands();
            {front,Username, GameRoom, Charge} ->
            io:format("Entrei no commands: front ~p ~n", [Username]),
              GameRoom ! {front,Username,Charge},
              commands();
        {Socket,U, GameRoom} ->
            io:format("Entrei no commands: Socket ~p, Username ~p ~n", [Socket,U]),
          GameRoom ! {time,Socket,U},
          commands();
        {generate_monsters, GameRoom} ->
          io:format("Entrei no commands do generate_monsters ~n"),
          GameRoom ! {generate_monsters, GameRoom},
          commands()
      end.

      charge_energy(GameRoom) ->
        receive
         {front_energy,Username, GameRoom} -> 
            timer:send_after(4000,GameRoom,{autocharge,Username,"Fe"}),
            charge_energy(GameRoom);
         {left_energy,Username, GameRoom} ->
            timer:send_after(4000,GameRoom,{autocharge,Username,"Le"}),
            charge_energy(GameRoom);
         {right_energy,Username, GameRoom} ->
            timer:send_after(4000,GameRoom,{autocharge,Username,"Re"}),
            charge_energy(GameRoom)
        end.

      % WaitingList -> [{Username, Pid}]
      % Levels -> mapa dos níveis dos users
waiting(WaitingList, Levels, NumGameRoom) ->
  io:format("a esperar no waiting ~n"),
  receive 

      {remove_level, Username} ->
          NewLevels = maps:remove(Username, Levels),
          waiting(WaitingList, NewLevels, NumGameRoom);

      {game_over, WinnerUser} ->
                Level = maps:get(WinnerUser, Levels),
                NewLevels = maps:update(WinnerUser, Level+1, Levels),
                io:format("tamanho da UpdatedLevels: ~p  e da WaitingList ~p ~n",[NewLevels, WaitingList]),
                waiting(WaitingList, NewLevels, NumGameRoom);


        {enter_waiting_list, Username, Pid} ->
          case maps:find(Username,Levels) of
            error -> 
              NewLevels = maps:put(Username,1,Levels),

              NewWaitingList = [{Username, Pid} | WaitingList],
              case match_making(NewWaitingList, NewLevels, NumGameRoom) of
                {match, Pid1, Pid2, GameRoom} -> 
                  io:format("GameRoom : ~p ~n",[GameRoom]),
                  Pid1 ! {ready,GameRoom},
                  Pid2 ! {ready,GameRoom},
                  ?MODULE ! {generate_monsters, GameRoom},
                  spawn(fun() -> update_monsters(GameRoom) end),
                  User1 = hd([Usern || {Usern, PidUs1} <- NewWaitingList, PidUs1 == Pid1]),
                  User2 = hd([Usern || {Usern, PidUs2} <- NewWaitingList, PidUs2 == Pid2]),
                  %RemovedWaitingList1 = [NewWaitingList -- [{User1, Pid1}]],
                  %RemovedWaitingList2 = [RemovedWaitingList1 -- [{User2, Pid2}]],
                  RemovedWaitingList1 = lists:delete({User1, Pid1}, NewWaitingList),
                  RemovedWaitingList2 = lists:delete({User2, Pid2}, RemovedWaitingList1),
                  io:format("User1: ~p ; User2: ~p ; RemovedWaitingList1: ~p ; RemovedWaitingList2: ~p ~n",[User1, User2, RemovedWaitingList1, RemovedWaitingList2]),
                  waiting(RemovedWaitingList2,NewLevels, NumGameRoom+1);
                fail -> %falhou match making
                  waiting(NewWaitingList, NewLevels, NumGameRoom)
              end;
           
            _ ->
              NewWaitingList = [{Username, Pid} | WaitingList],
              case match_making(NewWaitingList, Levels, NumGameRoom) of
                {match, Pid1, Pid2, GameRoom} -> 
                  Pid1 ! {ready, GameRoom},
                  Pid2 ! {ready, GameRoom},
                  ?MODULE ! {generate_monsters, GameRoom},
                  spawn(fun() -> update_monsters(GameRoom) end),
                  %spawn(fun() -> charge_energy(GameRoom) end),
                  User1 = hd([Usern || {Usern, PidUs1} <- NewWaitingList, PidUs1 == Pid1]),
                  User2 = hd([Usern || {Usern, PidUs2} <- NewWaitingList, PidUs2 == Pid2]),
                  RemovedWaitingList1 = lists:delete({User1, Pid1}, NewWaitingList),
                  RemovedWaitingList2 = lists:delete({User2, Pid2}, RemovedWaitingList1),
                  io:format("User1: ~p ; User2: ~p ; RemovedWaitingList1: ~p ; RemovedWaitingList2: ~p ~n",[User1, User2, RemovedWaitingList1, RemovedWaitingList2]),
                  %RemovedWaitingList1 = [NewWaitingList -- [{User1, Pid1}]],
                  %RemovedWaitingList2 = [RemovedWaitingList1 -- [{User2, Pid2}]],
                  waiting(RemovedWaitingList2,Levels, NumGameRoom+1);
                fail ->
                  waiting(NewWaitingList,Levels,NumGameRoom)
               end
          end
end.


      match_making(WaitingList, Levels, NumGameRoom) ->
        Num = lists:flatlength(WaitingList),
        if 
          Num < 2 ->
            fail;
          true ->
            [H | T] = WaitingList,
            {Username, Pid} = H,
            LevelUser = maps:get(Username, Levels),

            LMatch =  [{Usern, Lvl} || {Usern, Lvl} <- maps:to_list(Levels), LevelUser == Lvl, Usern /= Username, maps:is_key(Usern, maps:from_list(WaitingList)) == true],
            io:format("WaitingList : ~p e LMatch : ~p ~n", [WaitingList, LMatch]),
            case lists:flatlength(LMatch) of
              N when N >= 1 ->
                io:format("tamanho da WaitingList: ~p e da  ~n",[WaitingList]),
                {UserMatched, _} = hd(LMatch),
                OpponentPid = hd([Pid2 || {UserOpp, Pid2} <- WaitingList, UserOpp /= Username, UserOpp == UserMatched]),
                PidSelf = self(),
                spawn(fun() -> start(NumGameRoom, PidSelf) end),
                io:format("numRoom: ~p , jog1: ~p jog2 ~p", [NumGameRoom, Pid, OpponentPid]),
                receive
                  {ok, PidState} ->
                    io:format("Estou a criar a GameRoom: ~p ~n", [PidState]),
                    {match, Pid, OpponentPid, PidState}
                 end;
              _ -> match_making(T, Levels, NumGameRoom)
            end
          end.

      ranking(RankingScore, RankingLevel) ->
        receive
          {remove_level, Username} ->
            NewRankingLevel = maps:remove(Username, RankingLevel),
            ranking(RankingScore, NewRankingLevel);

          {remove_score, Username} ->
            NewRankingScore = maps:remove(Username, RankingScore),
            ranking(NewRankingScore, RankingLevel);

          {game_over_add_score, LoserUsername, WinnerUsername, ScoreL, ScoreW} ->
            OldScoreL = maps:get(LoserUsername, RankingScore),
            NewScoreL = max(OldScoreL, ScoreL),
            NewRankingScore1 = maps:put(LoserUsername, NewScoreL, RankingScore),

            OldScoreW = maps:get(WinnerUsername, NewRankingScore1),
            NewScoreW = max(OldScoreW, ScoreW),
            NewRankingScore2 = maps:put(WinnerUsername, NewScoreW, NewRankingScore1),

            ranking(NewRankingScore2, RankingLevel);

          {game_over_add_level, WinnerUsername} ->
            OldLevel = maps:get(WinnerUsername, RankingLevel),
            NewRankingLevel = maps:put(WinnerUsername, OldLevel+1, RankingLevel),

            ranking(RankingScore, NewRankingLevel);

          {add_ranking, Username} ->
            case maps:find(Username, RankingScore) of
                error ->  
                          NewRankingScore = maps:put(Username,0,RankingScore),
                          NewRankingLevel = maps:put(Username,1,RankingLevel),
                          ranking(NewRankingScore, NewRankingLevel);
                _ -> 
                          ranking(RankingScore, RankingLevel)
            end;

          {request_level, Socket1, Socket2, WinnerUsername, LoserUsername} ->
            ListSocket = [Socket1 | [Socket2]],
            WL = maps:get(WinnerUsername, RankingLevel),
            LL = maps:get(LoserUsername, RankingLevel),
            [gen_tcp:send(Sock, list_to_binary("level_info " ++ WinnerUsername ++ " "
                          ++ integer_to_list(WL) ++  " " ++ LoserUsername ++ " "
                          ++ integer_to_list(LL) ++ "\n")) || Sock <- ListSocket],
            ranking(RankingScore, RankingLevel);

          {request_top_score, Socket1, Socket2} ->
            ListSocket = [Socket1 | [Socket2]],
            ListRankingScore = maps:to_list(RankingScore),
            [gen_tcp:send(Sock,list_to_binary("ranking_score " ++ UsernameS ++ " " ++ integer_to_list(ScoreS) ++ "\n"))
                            || {UsernameS,ScoreS} <- ListRankingScore, Sock <- ListSocket],
            ranking(RankingScore, RankingLevel);

          {request_top_level, Socket1, Socket2} ->
              ListSocket = [Socket1 | [Socket2]],
              ListRankingLevel = maps:to_list(RankingLevel),
             [gen_tcp:send(Sock,list_to_binary("ranking_level " ++ UsernameL ++ " " ++ integer_to_list(LevelL) ++ "\n"))
                          || {UsernameL,LevelL} <- ListRankingLevel, Sock <- ListSocket],
              ranking(RankingScore, RankingLevel)

          end.