-module(server).
-compile(export_all).
-import(loginmanager,[start/0, logged/1]).
-import(state,[]).


server(Port) -> 
  spawn(fun() -> start() end), %inicia o loginmanager
  WaitRoom = spawn(fun() -> waiting([], #{}) end),
  register(wait, WaitRoom),
  Command = spawn(fun() -> commands() end),
  register(?MODULE,Command),
  state:start(), %inicia o state
  Room = spawn(fun() -> room([]) end),
  spawn(fun() -> update_monsters() end),
  Charge = spawn(fun() -> charge_energy() end),
  {ok,LSock} = gen_tcp:listen(Port,[binary, {packet, line}, {reuseaddr, true}]),
  register(charge,Charge),
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
        {line, Data,Socket} ->
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
              {ok,N} -> gen_tcp:send(Socket,<<"ok_login\n">>),
                  Room ! {enter,Socket},

                  wait ! {enter_waiting_list, U, self()},
                  %%wait ! {game_over},
                  receive
                      ready ->
                          io:format("Estou no ready2 ~p ~n", [U]),
                          ?MODULE ! {Socket,U},
                          ?MODULE ! {online,add,U},
                          gen_tcp:send(Socket,<<"ready\n">>),
                          userauthenticated(Sock, Room)
                  end;
              _ -> gen_tcp:send(Socket,<<"invalid_login\n">>)
              end;

          
          "\\create_account " ++ Dados ->
            St = string:tokens(Dados, " "),
            %debug -------
            io:format("St: ~p ~n",[St]),
            [U | P] = St,
            case loginmanager:create_account(U, P, Socket) of
              {ok,N} -> gen_tcp:send(Socket,<<"ok_create_account\n">>);
              _ -> io:format("Erro a criar conta"),
              gen_tcp:send(Socket,<<"user_exists\n">>)
            end;

    "\\close_account " ++ Dados ->
            St = string:tokens(Dados, " "),
            [U | P] = St,
            io:format("user ~p ~n", [U]),
            io:format("pass ~p ~n", [P]),
            case loginmanager:close_account(U, P, Socket) of
              ok -> gen_tcp:send(Socket,<<"ok_close_account\n">>);
              _ -> gen_tcp:send(Socket,<<"user_not_exists\n">>)
            end;

            _ -> invalid
           end,
           
           user(Sock,Room);

        {tcp_closed, _} ->
            Room ! {leave, self()};
        {tcp_error, _, _} ->
            Room ! {leave, self()}
    end.

    userauthenticated(Sock,Room) ->
      receive 
       {line, Data} ->
            gen_tcp:send(Sock, Data),
            userauthenticated(Sock, Room);
        {tcp, Socket, Data} ->
          StrData = binary:bin_to_list(Data),
          case StrData of 

            "\\logout " ++ Dados ->
            St = string:tokens(Dados, " "),
            [U | P] = St,
            case loginmanager:logout(U, P, Socket) of
              ok -> gen_tcp:send(Socket,<<"ok_logout\n">>),
                  Room ! {leave,Sock}, user(Sock,Room);
              _ -> userauthenticated(Sock,Room)
            end;

            "\\left\n" ->
              Username = logged(Socket),
              io:format("Fez left ~n"),
              ?MODULE ! {left,Username},
              Room ! {line,Data,Socket},
              userauthenticated(Sock,Room);

            "\\right\n" ->
              Username = logged(Socket),
              io:format("Fez right ~n"),
              ?MODULE ! {right,Username},
              Room ! {line,Data,Socket},
              userauthenticated(Sock,Room);

              "\\front\n" ->
              Username = logged(Socket),
              io:format("Fez front ~n"),
              ?MODULE ! {front,Username},
              Room ! {line,Data,Socket},
              userauthenticated(Sock,Room);

            _ ->
          %Room ! {line, Data,Socket}, não é necessário?
          userauthenticated(Sock, Room)
        end;
        {tcp_closed, _} ->
            Room ! {leave, self()};
        {tcp_error, _, _} ->
            Room ! {leave, self()}
    end.

    update_monsters() ->
    timer:send_after(80,state,{monsters_upt,self()}),
    receive
      {repeat} ->
          update_monsters()
    end.

    commands() ->
      receive
        {online,add,Username} ->
            io:format("Entrei no commands: add ~p ~n", [Username]),
          state ! {online,add,Username},
          commands();
        {left,Username} ->
            io:format("Entrei no commands: left ~p ~n", [Username]),
          state ! {left,Username},

          commands();
          {right,Username} ->
            io:format("Entrei no commands: right ~p ~n", [Username]),
              state ! {right,Username},
              commands();
            {front,Username} ->
            io:format("Entrei no commands: front ~p ~n", [Username]),
              state ! {front,Username},
              commands();
        {Socket,U} ->
            io:format("Entrei no commands: Socket ~p, Username ~p ~n", [Socket,U]),
          state ! {time,Socket,U},
          commands();
        {generate_monsters} ->
          io:format("Entrei no commands do generate_monsters ~n"),
          state ! {generate_monsters},
          commands()
      end.

      charge_energy() ->
        receive
         {front_energy,Username} -> 
            timer:send_after(4000,state,{autocharge,Username,"Fe"}),
            charge_energy();
         {left_energy,Username} ->
            timer:send_after(4000,state,{autocharge,Username,"Le"}),
            charge_energy();
         {right_energy,Username} ->
            timer:send_after(4000,state,{autocharge,Username,"Re"}),
            charge_energy()
        end.

      % WaitingList -> [{Username, Pid}]
      % Levels -> mapa dos níveis dos users
waiting(WaitingList, Levels) ->
  io:format("a esperar no waiting ~n"),
  receive 
      {game_over, WinnerUser} ->
                Level = maps:get(WinnerUser, Levels),
                NewLevels = maps:update(WinnerUser, Level+1, Levels),
                io:format("tamanho da UpdatedLevels: ~p  e da WaitingList ~p ~n",[NewLevels, WaitingList]),
                waiting(WaitingList, NewLevels);


        {enter_waiting_list, Username, Pid} ->
          case maps:find(Username,Levels) of
            error -> 
              NewLevels = maps:put(Username,1,Levels),

              NewWaitingList = [{Username, Pid} | WaitingList],
              case match_making(NewWaitingList, NewLevels) of
                {match, Pid1, Pid2} -> 
                  Pid1 ! ready,
                  Pid2 ! ready,
                  ?MODULE ! {generate_monsters},
                  User1 = hd([Usern || {Usern, Pid} <- NewWaitingList, Pid == Pid1]),
                  User2 = hd([Usern || {Usern, Pid} <- NewWaitingList, Pid == Pid2]),
                  %RemovedWaitingList1 = [NewWaitingList -- [{User1, Pid1}]],
                  %RemovedWaitingList2 = [RemovedWaitingList1 -- [{User2, Pid2}]],
                  RemovedWaitingList1 = lists:delete({User1, Pid1}, NewWaitingList),
                  RemovedWaitingList2 = lists:delete({User2, Pid2}, RemovedWaitingList1),
                  io:format("User1: ~p ; User2: ~p ; RemovedWaitingList1: ~p ; RemovedWaitingList2: ~p ~n",[User1, User2, RemovedWaitingList1, RemovedWaitingList2]),
                  waiting(RemovedWaitingList2,NewLevels);
                fail -> %falhou match making
                  waiting(NewWaitingList, NewLevels)
              end;
           
            _ ->
              NewWaitingList = [{Username, Pid} | WaitingList],
              case match_making(NewWaitingList, Levels) of
                {match, Pid1, Pid2} -> 
                  Pid1 ! ready,
                  Pid2 ! ready,
                  ?MODULE ! {generate_monsters},
                  User1 = hd([Usern || {Usern, Pid} <- NewWaitingList, Pid == Pid1]),
                  User2 = hd([Usern || {Usern, Pid} <- NewWaitingList, Pid == Pid2]),
                  RemovedWaitingList1 = lists:delete({User1, Pid1}, NewWaitingList),
                  RemovedWaitingList2 = lists:delete({User2, Pid2}, RemovedWaitingList1),
                  io:format("User1: ~p ; User2: ~p ; RemovedWaitingList1: ~p ; RemovedWaitingList2: ~p ~n",[User1, User2, RemovedWaitingList1, RemovedWaitingList2]),
                  %RemovedWaitingList1 = [NewWaitingList -- [{User1, Pid1}]],
                  %RemovedWaitingList2 = [RemovedWaitingList1 -- [{User2, Pid2}]],
                  waiting(RemovedWaitingList2,Levels);
                fail ->
                  waiting(NewWaitingList,Levels)
               end
          end
end.


      match_making(WaitingList, Levels) ->
        Num = lists:flatlength(WaitingList),
        if 
          Num < 2 ->
            fail;
          true ->
            [H | T] = WaitingList,
            {Username, Pid} = H,
            LevelUser = maps:get(Username, Levels),
            LMatch = [{Usern, Lvl} || {Usern, Lvl} <- maps:to_list(Levels), LevelUser == Lvl, Usern /= Username],
            case lists:flatlength(LMatch) of
              N when N >= 1 ->
                io:format("tamanho da WaitingList: ~p ~n",[WaitingList]),
                OpponentPid = hd([Pid2 || {UserOpp, Pid2} <- WaitingList, UserOpp /= Username]),
                io:format("Pid1 ~p e PidOpponent ~p ~n",[Pid, OpponentPid]),
                {match, Pid, OpponentPid};
              _ -> fail
            end
          end.
