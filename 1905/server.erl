-module(server).
-compile(export_all).
-import(loginmanager,[start/0, logged/1]).
-import(state,[]).


server(Port) -> 
  spawn(fun() -> start() end), %inicia o loginmanager
  state:start(), %inicia o state
  Command = spawn(fun() -> commands() end),
  Room = spawn(fun() -> room([]) end),
  spawn(fun() -> update_monsters() end),
  {ok,LSock} = gen_tcp:listen(Port,[binary, {packet, line}, {reuseaddr, true}]),
  register(?MODULE,Command),
  ?MODULE ! {generate_monsters},
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
                  ?MODULE ! {Socket,U},
                  ?MODULE ! {online,add,U},
                  userauthenticated(Sock, Room);
              _ -> gen_tcp:send(Socket,<<"invalid_login\n">>)
              end;

          
          "\\create_account " ++ Dados ->
            St = string:tokens(Dados, " "),
            %debug -------
            io:format("St: ~p ~n",[St]),
            [U | P] = St,
            case loginmanager:create_account(U, P, Socket) of
              {ok,N} -> gen_tcp:send(Socket,<<"ok_create_account\n">>);
              _ -> gen_tcp:send(Socket,<<"user_exists\n">>)
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
              ok -> %gen_tcp:send(Socket,<<"ok_logout\n">>),
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
          state ! {generate_monsters},
          commands()
      end.
