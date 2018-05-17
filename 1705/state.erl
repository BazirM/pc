-module(state).
-export([start/0]).
-import(avatar,[generateAvatar/0,generate_green_monsters/0,generate_red_monsters/0]).

start() ->
	Pid = spawn(fun() -> state(#{},[],#{},#{}) end),
	register(?MODULE,Pid).

%funcao que recebe socket do user que acabou de fazer login e map dos Online e envia mensagem
statelogin(Online,Socket,GreenMonsters,RedMonsters) ->
  case maps:to_list(Online) of
    [] -> fail;
    PList ->
  			[gen_tcp:send(Socket,list_to_binary("online " ++ Username ++ " 0 " ++ integer_to_list(Speed) ++ " " ++ float_to_list(Dir)
			++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(H)
			++ " " ++ integer_to_list(W) ++ " " ++ integer_to_list(Fe) ++ "\n"))
            || {Username,{Speed, Dir, X, Y, H, W,Fe}} <- PList]    
  end,

  case maps:to_list(GreenMonsters) of
  	[] -> skip;
  	GM ->
  		[gen_tcp:send(Socket,list_to_binary("add_green_monster " ++ integer_to_list(I) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n"))
                 || {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- GM]
    end,

  case maps:to_list(RedMonsters) of
  	[] -> skip;
  	RM ->
  		[gen_tcp:send(Socket,list_to_binary("add_red_monster " ++ integer_to_list(I) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n"))
                 || {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- RM]
    end.
%Online #{Username => Avatar = ({Speed,Dir,X,Y,H,W})}
% GreenMonsters #{I => Monster = ({Speed,X,Y,H,W,Type})}
% RedMonsters
state(Online,Socket,GreenMonsters,RedMonsters) ->
	receive
		{online, add, Username} ->
			{Speed, Dir, X, Y, H, W,Fe} = generateAvatar(),
			%0 é o score
			Data = "online " ++ Username ++  " 0 " ++ integer_to_list(Speed) ++ " " ++ float_to_list(Dir)
			++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(H)
			++ " " ++ integer_to_list(W) ++ " " ++ integer_to_list(Fe) ++ "\n",
			[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
			NewOnline = maps:put(Username, {Speed, Dir, X, Y, H, W,Fe},Online),
			state(NewOnline,Socket,GreenMonsters,RedMonsters);
		
		{time,Sock,Username} ->
			{_,Seconds,_} = os:timestamp(),
			% Associar depois os segundos com a pontuação
			statelogin(Online,Sock,GreenMonsters,RedMonsters),
			state(Online,[Sock | Socket],GreenMonsters,RedMonsters);

		{left,Username} ->
			case maps:is_key(Username,Online) of
				false -> state(Online,Socket,GreenMonsters,RedMonsters);
				true ->
					{Speed, Dir, X, Y, H, W,Fe} = maps:get(Username,Online),
					O = maps:update(Username,{Speed, Dir-10, X, Y, H, W,Fe},Online),
					Data = "on_update_left " ++ Username ++ " " ++ float_to_list(Dir-10) ++ " " ++ "\n",
					[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
					state(O,Socket,GreenMonsters,RedMonsters)
			end;

		{right,Username} ->
			case maps:is_key(Username,Online) of
				false -> state(Online,Socket,GreenMonsters,RedMonsters);
				true ->
					{Speed, Dir, X, Y, H, W, Fe} = maps:get(Username,Online),
					O = maps:update(Username,{Speed, Dir+10, X, Y, H, W,Fe},Online),
					Data = "on_update_right " ++ Username ++ " " ++ float_to_list(Dir+10) ++ " " ++ "\n",
					[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
					state(O,Socket,GreenMonsters,RedMonsters)
			end;

		{front,Username} ->
			case maps:is_key(Username,Online) of
				false -> state(Online,Socket,GreenMonsters,RedMonsters);
				true -> 
						{Speed, Dir, X, Y, H, W, Fe} = maps:get(Username,Online),
						case Fe of
							N when N > 0 ->
								Updated_X = (math:cos(Dir*math:pi()/180)*Speed) + X,
								Updated_Y = (math:sin(Dir*math:pi()/180)*Speed) + Y,
								O = maps:update(Username,{Speed, Dir, Updated_X, Updated_Y, H, W, Fe-5},Online),
								Data = "on_update_front " ++ Username ++ " " ++ float_to_list(Updated_X) ++ " " ++ float_to_list(Updated_Y) ++ " " ++ integer_to_list(Fe-5) ++ "\n",
								[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket];

							0 -> 
								O = maps:update(Username,{Speed, Dir, X, Y, H, W, Fe},Online),
								Data = "on_update_front " ++ Username ++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(Fe) ++ "\n",
								[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket]
						end,
						state(O,Socket,GreenMonsters,RedMonsters)
			end;

		{generate_monsters} ->
				GM = maps:put(0,generate_green_monsters(),GreenMonsters),
				GM2 = maps:put(1,generate_green_monsters(),GM),
				%RM = maps:put(0,generate_red_monsters(),RedMonsters),
				Red = spawn(fun() -> create_red_monster() end),
				spawn(fun() -> notify_red(Red) end), %para ficar a sinalizar de 10 em 10s
				state(Online,Socket,GM2,RedMonsters);

		{red_create, From} ->
			{Speed, X, Y, H, W,DirX,DirY, Type} = generate_red_monsters(),
			Id = maps:size(RedMonsters)+1,
			io:format("ID incrementado: ~p ~n",[Id]),
			Data = "add_red_monster " ++ integer_to_list(Id) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n",
                [gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
			RM = maps:put(Id,{Speed, X, Y, H, W,DirX,DirY, Type},RedMonsters),
			state(Online,Socket,GreenMonsters,RM);
		
		{monsters_upt, From} ->
			  GreenM = maps:to_list(GreenMonsters),
              [gen_tcp:send(Sock,list_to_binary("green_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
                ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- GreenM],
              RedM = maps:to_list(RedMonsters),
              [gen_tcp:send(Sock,list_to_binary("red_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
                ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- RedM],

              NewGreenMonsters = check_collision_wall_monsters(maps:to_list(GreenMonsters),GreenMonsters,maps:size(GreenMonsters)),
              NewRedMonsters = check_collision_wall_monsters(maps:to_list(RedMonsters),RedMonsters,maps:size(RedMonsters)),
              %{Speed,X,Y,H,W,Type} = maps:get(0,GreenMonsters),
              %{Speed2,X2,Y2,H2,W2,Type} = maps:get(1,GreenMonsters),
              %Green_Updated = maps:update(0,{Speed,X+0.5,Y+0.5,H,W,Type},GreenMonsters),
              %Green_Updated2 = maps:update(1,{Speed2,X2+0.7,Y2+0.7,H2,W2,Type},Green_Updated),
              %RedMonsters2 = update_allRed(maps:to_list(RedMonsters),RedMonsters,maps:size(RedMonsters)),
              
              From ! {repeat},
              state(Online,Socket,NewGreenMonsters,NewRedMonsters) 
		end.

create_red_monster() ->
	receive
		{red_monster,From} ->
			state ! {red_create,self()},
			From ! {repeat}
	end,
	create_red_monster().

notify_red(Red) ->
	timer:send_after(10000,Red,{red_monster,self()}),
	receive
		{repeat} -> notify_red(Red)
	end.


%update_allRed(L,RedMonsters,N) when N > 0 ->
%	[Head|T] = L,
%	io:format("~p ~n",[Head]),
%	{Id,{Speed,X,Y,H,W,Type}} = Head,
	%GM = maps:update(Id,{Speed,X+rand:uniform()+0.0,Y+rand:uniform()+0.0,H,W,Type},RedMonsters),
%	GM = maps:update(Id,{Speed,X+Speed,Y+Speed,H,W,Type},RedMonsters),
%	update_allRed(T,GM,N-1);
%update_allRed(_,GM,0) -> 
%	GM.

check_collision_wall_monsters(ListMonster,Monsters,N) when N > 0 ->
	[Head|T] = ListMonster,
	{Id,{Speed,X,Y,H,W,DirX,DirY,Type}} = Head,
	if X > 1024-(W/2) ; X < W/2 ->
		check_collision_wall_monsters(T,maps:update(Id,{Speed,X+(Speed*(-DirX)),Y,H,W,-DirX,DirY,Type},Monsters),N-1);
	Y > 700-(H/2) ; Y < H/2 ->
		check_collision_wall_monsters(T,maps:update(Id,{Speed,X,Y+(Speed*(-DirY)),H,W,DirX,-DirY,Type},Monsters),N-1);
	true ->
		check_collision_wall_monsters(T,maps:update(Id,{Speed,X+(Speed*(DirX)),Y+(Speed*(DirY)),H,W,DirX,DirY,Type},Monsters),N-1)
	end;
check_collision_wall_monsters(_,Monsters,0) ->
	Monsters.
