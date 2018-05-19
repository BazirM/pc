-module(state).
-export([start/0]).
-import(avatar,[generateAvatar/0,generate_green_monsters/0,generate_red_monsters/0]).

start() ->
	Pid = spawn(fun() -> state(#{},[],#{},#{}) end),
	register(?MODULE,Pid).

%funcao que recebe socket do user que acabou de fazer login e map dos Online e envia mensagem
statelogin(Online,Socket,GreenMonsters,RedMonsters) ->
  case maps:to_list(Online) of
    [] -> none;
    PList ->
  			[gen_tcp:send(Socket,list_to_binary("online " ++ Username ++ " 0 " ++ integer_to_list(Speed) ++ " " ++ float_to_list(Dir)
			++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(H)
			++ " " ++ integer_to_list(W) ++ " " ++ integer_to_list(Fe) ++ "\n"))
            || {Username,{Speed, Dir, X, Y, H, W,Fe}} <- PList]    
  end,

  case maps:to_list(GreenMonsters) of
  	[] -> none;
  	GM ->
  		[gen_tcp:send(Socket,list_to_binary("add_green_monster " ++ integer_to_list(I) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n"))
                 || {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- GM]
    end,

  case maps:to_list(RedMonsters) of
  	[] -> none;
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
						case check_boundaries_players(maps:to_list(Online)) of

							{front_ok} ->
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
									state(O,Socket,GreenMonsters,RedMonsters);
							{game_over, LostUsername} ->
								Message = "game_over " ++ LostUsername ++ "\n",
              					[gen_tcp:send(Sock,list_to_binary(Message)) || Sock <- Socket],
              					%Online,Socket,GreenMonsters,RedMonsters
              					state(#{},[],GreenMonsters,#{})
						end
			end;

		{generate_monsters} ->
				GM = maps:put(0,generate_green_monsters(),GreenMonsters),
				GM2 = maps:put(1,generate_green_monsters(),GM),
				%RM = maps:put(0,generate_red_monsters(),RedMonsters),
				RM = maps:put(0,generate_red_monsters(),RedMonsters),
				Red = spawn(fun() -> create_red_monster() end),
				spawn(fun() -> notify_red(Red) end), %para ficar a sinalizar de 10 em 10s
				state(Online,Socket,GM2,RM);

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
			  %GreenM = maps:to_list(GreenMonsters),
              %[gen_tcp:send(Sock,list_to_binary("green_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
               % ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- GreenM],
              %RedM = maps:to_list(RedMonsters),
              %[gen_tcp:send(Sock,list_to_binary("red_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
              %  ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- RedM],

              %check_boundaries_monsters testa a colisão com as paredes do jogo.
              

              NewGreenMonsters = check_boundaries_monsters(maps:to_list(GreenMonsters),GreenMonsters,maps:size(GreenMonsters)),
              NewRedMonsters = check_boundaries_monsters(maps:to_list(RedMonsters),RedMonsters,maps:size(RedMonsters)),
              
              case check_collision_RedMonsters(maps:to_list(Online),RedMonsters) of 
					{game_upt_continue} -> 
              					NRM = maps:to_list(NewRedMonsters),
              					[gen_tcp:send(Sock,list_to_binary("red_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
                ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- NRM],
              					case check_collision_GreenMonsters(maps:to_list(Online),GreenMonsters) of 
              						{game_upt_continue} -> 
              							NGM = maps:to_list(NewGreenMonsters),
              							[gen_tcp:send(Sock,list_to_binary("green_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
               							 ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- NGM],
              							From ! {repeat},
              							state(Online,Socket,NewGreenMonsters,NewRedMonsters);
              						
              						{charge,Username,IM} ->
              							NGM = maps:to_list(NewGreenMonsters),
              							[gen_tcp:send(Sock,list_to_binary("green_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
                						++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- NGM],
                						{USpeed, UDir, UX, UY, UH, UW, UFe} = maps:get(Username,Online),
                						O = maps:update(Username,{USpeed, UDir, UX, UY, UH, UW, 100},Online),
              							Data = "charge " ++ Username ++ " " ++ integer_to_list(100) ++ "\n",
              							[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
              							RemovedGreen = maps:remove(IM,NewGreenMonsters),
              							Data2 = "remove_green_monster " ++ integer_to_list(IM) ++ "\n",
              							[gen_tcp:send(Sock,list_to_binary(Data2)) || Sock <- Socket],
              							
              							%Procura o valor máximo de ID dos montros, para atribuir MAX+1 ao novo ID a ser criado.
              							%Cria um novo monstro verde
              							MAX = lists:max(maps:keys(NewGreenMonsters)),
              							{GSpeed, GX, GY, GH, GW,GDirX,GDirY,GType} = generate_green_monsters(),
              							GM = maps:put(MAX+1,{GSpeed,GX,GY,GH,GW,GDirX,GDirY,GType},RemovedGreen),
              							Data3 = "add_green_monster " ++ integer_to_list(MAX+1) ++ " " ++ integer_to_list(GSpeed) ++ " " ++ float_to_list(GX) 
                						++ " " ++ float_to_list(GY) ++ " " ++ float_to_list(GH) ++ " " ++ float_to_list(GW) ++ " " ++ integer_to_list(GType) ++ "\n",
                						[gen_tcp:send(Sock,list_to_binary(Data3)) || Sock <- Socket],
              							From ! {repeat},
              							state(O,Socket,GM,NewRedMonsters)
              					end;
            
              		{game_over,Username} ->
              					Message = "game_over " ++ Username ++ "\n",
              					[gen_tcp:send(Sock,list_to_binary(Message)) || Sock <- Socket],
              					%Online,Socket,GreenMonsters,RedMonsters
              					state(#{},[],GreenMonsters,#{})
              end

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

check_boundaries_monsters(ListMonster,Monsters,N) when N > 0 ->
	[Head|T] = ListMonster,
	{Id,{Speed,X,Y,H,W,DirX,DirY,Type}} = Head,
	if X > 1024-(W/2) ; X < W/2 ->
		check_boundaries_monsters(T,maps:update(Id,{Speed,X+(Speed*(-DirX)),Y,H,W,-DirX,DirY,Type},Monsters),N-1);
	Y > 700-(H/2) ; Y < H/2 ->
		check_boundaries_monsters(T,maps:update(Id,{Speed,X,Y+(Speed*(-DirY)),H,W,DirX,-DirY,Type},Monsters),N-1);
	true ->
		check_boundaries_monsters(T,maps:update(Id,{Speed,X+(Speed*(DirX)),Y+(Speed*(DirY)),H,W,DirX,DirY,Type},Monsters),N-1)
	end;
check_boundaries_monsters(_,Monsters,0) ->
	Monsters.


check_boundaries_players([Head|T]) ->
	{Username,{Speed,Dir,X,Y,H,W,Fe}} = Head,
	if X > 1024-(W/2) ; X < W/2 ->
		{game_over,Username};
	Y > 700-(H/2) ; Y < H/2 ->
		{game_over,Username};
	true -> 
		check_boundaries_players(T)
	end;

check_boundaries_players([]) ->
		{front_ok}.

distance(X1,Y1,X2,Y2) ->
	math:sqrt( math:pow(abs(X2-X1),2) + math:pow(abs(Y2-Y1),2)).

%Lista de Online, Map de Monsters, N é o numero de monstros no map
check_collision_RedMonsters([Head|T],Monsters) ->
	{Username,{Speed, Dir, XU, YU, HU, WU,Fe}} = Head,
	%lista das distancias entre o avatar (Head) e cada um dos monstros
	Distances = [{distance(XU,YU,X2,Y2),H} || {I,{Speed,X2,Y2,H,W,DirX,DirY,Type}} <- maps:to_list(Monsters)],
	%para verificar se houve alguma distancia que falhe a condicao
	TestDistances = [ {Val,H} ||  {Val,H} <- Distances , Val < ((HU/2) + (H/2))],
	case lists:flatlength(TestDistances) of
		N when N > 0 -> 
			{game_over,Username};
	    0 ->
			check_collision_RedMonsters(T,Monsters)
	end;
check_collision_RedMonsters([],Monsters) -> 
	{game_upt_continue}.

check_collision_GreenMonsters([Head|T],Monsters) ->
	{Username,{Speed, Dir, XU, YU, HU, WU,Fe}} = Head,
	%lista das distancias entre o avatar (Head) e cada um dos monstros
	Distances = [{distance(XU,YU,X2,Y2),H,I} || {I,{Speed,X2,Y2,H,W,DirX,DirY,Type}} <- maps:to_list(Monsters)],
	%para verificar se houve alguma distancia que falhe a condicao
	TestDistances = [ {Val,H,I} ||  {Val,H,I} <- Distances , Val < ((HU/2) + (H/2))],
	case lists:flatlength(TestDistances) of
		N when N > 0 -> 
			{ValM,HM,IM} = hd(TestDistances), %para poder saber o ID do monstro que colidiu com o utilizador
			{charge,Username,IM};
	    0 ->
			check_collision_GreenMonsters(T,Monsters)
	end;
check_collision_GreenMonsters([],Monsters) -> 
	{game_upt_continue}.
