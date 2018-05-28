-module(state).
-export([start/2]).
-import(avatar,[generateAvatar/0,generate_green_monsters/0,generate_red_monsters/0]).

start(NumGameRoom, PidServer) ->  %Online, Socket, GreenMonsters, RedMonsters, ScoreInGame
	io:format("Num do Room: ~p ~n", [NumGameRoom]),
	Pid = spawn(fun() -> state(NumGameRoom, #{},[],#{},#{},#{}) end),
	%register(?MODULE,Pid),
	io:format("Pid do PidServer: ~p , Pid do Room: ~p ~n", [PidServer, Pid]),
	PidServer ! {ok, Pid}.

%funcao que recebe socket do user que acabou de fazer login e map dos Online e envia mensagem
statelogin(Online,Socket,GreenMonsters,RedMonsters) ->
  case maps:to_list(Online) of
    [] -> none;
    PList ->
  			[gen_tcp:send(Socket,list_to_binary("online " ++ Username ++ " 0 " ++ integer_to_list(Speed) ++ " " ++ float_to_list(Dir)
			++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(H)
			++ " " ++ integer_to_list(W) ++ " " ++ integer_to_list(Fe) ++ " " ++ integer_to_list(Le) ++ " " ++ integer_to_list(Re) ++ "\n"))
            || {Username,{Speed, Dir, X, Y, H, W,Fe,Le,Re}} <- PList]    
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
state(NumGameRoom,Online,Socket,GreenMonsters,RedMonsters,ScoreInGame) ->
	receive
		{online, add, Username} ->
			io:format("A acrescentar o user ~p  no room ~n", [Username]),
			{Speed, Dir, X, Y, H, W,Fe,Le,Re} = generateAvatar(),
			%0 é o score
			Data = "online " ++ Username ++  " 0 " ++ integer_to_list(Speed) ++ " " ++ float_to_list(Dir)
			++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(H)
			++ " " ++ integer_to_list(W) ++ " " ++ integer_to_list(Fe) ++ " " ++ integer_to_list(Le) ++ " " ++ integer_to_list(Re) ++ "\n",
			[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
			NewOnline = maps:put(Username, {Speed, Dir, X, Y, H, W,Fe,Le,Re},Online),
			state(NumGameRoom, NewOnline, Socket, GreenMonsters, RedMonsters, ScoreInGame);
			
		
		{time,Sock,Username} ->
			{_,Seconds,_} = os:timestamp(),
			NewScoreInGame = maps:put(Username,Seconds,ScoreInGame),
			
			statelogin(Online,Sock,GreenMonsters,RedMonsters),
			state(NumGameRoom,Online,[Sock | Socket],GreenMonsters,RedMonsters,NewScoreInGame);

		{left,Username, Charge} ->
			case maps:is_key(Username,Online) of
				false -> state(NumGameRoom, Online,Socket,GreenMonsters,RedMonsters,ScoreInGame);
				true ->
					{Speed, Dir, X, Y, H, W,Fe,Le,Re} = maps:get(Username,Online),
					case Le of
						N when N > 0 ->
							O = maps:update(Username,{Speed, Dir-10, X, Y, H, W,Fe,Le-5,Re},Online),
							Data = "on_update_left " ++ Username ++ " " ++ float_to_list(Dir-10) ++ " " ++ integer_to_list(Le-5) ++ "\n",
							[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket];
						0 ->
							O = maps:update(Username,{Speed, Dir, X, Y, H, W,Fe,Le,Re},Online),
							Data = "on_update_left " ++ Username ++ " " ++ float_to_list(Dir) ++ " " ++ integer_to_list(Le) ++ "\n",
							[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket]
						end,
					Charge ! {left_energy,Username, self()},
					state(NumGameRoom, O,Socket,GreenMonsters,RedMonsters,ScoreInGame)
			end;

		{right,Username, Charge} ->
			case maps:is_key(Username,Online) of
				false -> state(NumGameRoom,Online,Socket,GreenMonsters,RedMonsters,ScoreInGame);
				true ->
					{Speed, Dir, X, Y, H, W, Fe,Le,Re} = maps:get(Username,Online),
					case Re of
						N when N > 0 ->
							O = maps:update(Username,{Speed, Dir+10, X, Y, H, W,Fe,Le,Re-5},Online),
							Data = "on_update_right " ++ Username ++ " " ++ float_to_list(Dir+10) ++ " " ++ integer_to_list(Re-5) ++ "\n",
							[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket];

						0 ->
							O = maps:update(Username,{Speed, Dir, X, Y, H, W,Fe,Le,Re},Online),
							Data = "on_update_right " ++ Username ++ " " ++ float_to_list(Dir) ++ " " ++ integer_to_list(Re) ++ "\n",
							[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket]
						end,
					Charge ! {right_energy,Username, self()},
					state(NumGameRoom,O,Socket,GreenMonsters,RedMonsters,ScoreInGame)
			end;

		{front,Username, Charge} ->
			case maps:is_key(Username,Online) of
				false -> state(NumGameRoom,Online,Socket,GreenMonsters,RedMonsters,ScoreInGame);
				true -> 
						case check_boundaries_players(maps:to_list(Online)) of

							{front_ok} ->
								{Speed, Dir, X, Y, H, W, Fe,Le,Re} = maps:get(Username,Online),
									case Fe of
										N when N > 0 ->
											Updated_X = (math:cos(Dir*math:pi()/180)*Speed) + X,
											Updated_Y = (math:sin(Dir*math:pi()/180)*Speed) + Y,
											O = maps:update(Username,{Speed, Dir, Updated_X, Updated_Y, H, W, Fe-5,Le,Re},Online),
											Data = "on_update_front " ++ Username ++ " " ++ float_to_list(Updated_X) ++ " " ++ float_to_list(Updated_Y) ++ " " ++ integer_to_list(Fe-5) ++ "\n",
											[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket];

										0 -> 
											O = maps:update(Username,{Speed, Dir, X, Y, H, W, Fe,Le,Re},Online),
											Data = "on_update_front " ++ Username ++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(Fe) ++ "\n",
											[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket]
									end,
									Charge ! {front_energy,Username, self()},
									state(NumGameRoom,O,Socket,GreenMonsters,RedMonsters,ScoreInGame);
							{game_over, LostUsername} ->
								{_,EndingTime,_} = os:timestamp(),
								InitialTime = maps:get(LostUsername,ScoreInGame),
								Score = EndingTime - InitialTime,
								Data = "score " ++ LostUsername ++ " " ++ integer_to_list(Score) ++ " " ++ integer_to_list(Score*2) ++ "\n",
								[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
								WinnerUsername = hd([WinnerU || {WinnerU, {Speed, Dir, X, Y, H, W, Fe ,Le ,Re}} <- maps:to_list(Online), WinnerU /= LostUsername]),
								Message = "game_over " ++ LostUsername ++ "\n",
				              	[gen_tcp:send(Sock,list_to_binary(Message)) || Sock <- Socket],
                 				ranking ! {game_over_add_score, LostUsername, WinnerUsername, Score, Score*2},
                 				ranking ! {game_over_add_level, WinnerUsername},
                 				[H | T] = Socket,
                 				Socket1 = H,
                 				Socket2 = hd(T),
                 				ranking ! {request_level, Socket1, Socket2, WinnerUsername, LostUsername},
                 				ranking ! {request_top_score, Socket1, Socket2},
                 				ranking ! {request_top_level, Socket1, Socket2},
                 				[gen_tcp:send(Sock, list_to_binary("score_info " ++ WinnerUsername ++ " "
                 					++ integer_to_list(Score*2) ++  " " ++ Username ++ " "
                 					++ integer_to_list(Score) ++ "\n")) || Sock <- Socket],
								wait ! {game_over, WinnerUsername},
								notifyRed ! stop,
				              	state(NumGameRoom,#{},[],#{},#{},#{})
						end
			end;

		{autocharge,Username,Energy} -> 
			case charge_time_energy(Username,Energy,Online) of
				{failure} -> state(NumGameRoom,Online,Socket,GreenMonsters,RedMonsters,ScoreInGame);
				{full} -> state(NumGameRoom,Online,Socket,GreenMonsters,RedMonsters,ScoreInGame);
				{NewOnline,Message} ->
					[gen_tcp:send(Sock,list_to_binary(Message)) || Sock <- Socket],
					state(NumGameRoom,NewOnline,Socket,GreenMonsters,RedMonsters,ScoreInGame)
			end;

		{generate_monsters, GRoom} ->
				GM = maps:put(0,generate_green_monsters(),GreenMonsters),
				GM2 = maps:put(1,generate_green_monsters(),GM),
				RM = maps:put(0,generate_red_monsters(),RedMonsters),
				Red = spawn(fun() -> create_red_monster(GRoom) end),
				io:format("Red Process: ~p ~n", [Red]),
				NotifyRed = spawn(fun() -> notify_red(Red) end), %para ficar a sinalizar de 10 em 10s
				register(notifyRed, NotifyRed),
				state(NumGameRoom,Online,Socket,GM2,RM,ScoreInGame);

		{red_create, From} ->
			{Speed, X, Y, H, W,DirX,DirY, Type} = generate_red_monsters(),
			Id = maps:size(RedMonsters)+1,
			io:format("ID incrementado: ~p ~n",[Id]),
			Data = "add_red_monster " ++ integer_to_list(Id) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n",
                [gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
			RM = maps:put(Id,{Speed, X, Y, H, W,DirX,DirY, Type},RedMonsters),
			state(NumGameRoom,Online,Socket,GreenMonsters,RM,ScoreInGame);
		
		{monsters_upt, From} ->

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
              							state(NumGameRoom,Online,Socket,NewGreenMonsters,NewRedMonsters,ScoreInGame);
              						
              						{charge,Username,IM} ->
              							NGM = maps:to_list(NewGreenMonsters),
              							[gen_tcp:send(Sock,list_to_binary("green_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
                						++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,DirX,DirY,Type}} <- NGM],
                						{USpeed, UDir, UX, UY, UH, UW, UFe, ULe, URe} = maps:get(Username,Online),
                						O = maps:update(Username,{USpeed, UDir, UX, UY, UH, UW, 100, 100, 100},Online),
                						Value = 100,
              							Data = "charge " ++ Username ++ " " ++ integer_to_list(Value) ++ " " ++ integer_to_list(Value) ++ " " ++integer_to_list(Value) ++ "\n",
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
              							state(NumGameRoom,O,Socket,GM,NewRedMonsters,ScoreInGame)
              					end;
            
              		{game_over,Username} ->
              		io:format("Game_OVER Red Monster!~n"),
              					{_,EndingTime,_} = os:timestamp(),
								InitialTime = maps:get(Username,ScoreInGame),
								Score = EndingTime - InitialTime,
								Data = "score " ++ Username ++ " " ++ integer_to_list(Score) ++ " " ++ integer_to_list(Score*2) ++ "\n",
								[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
								WinnerUsername = hd([WinnerU || {WinnerU, {Speed, Dir, X, Y, H, W, Fe ,Le ,Re}} <- maps:to_list(Online), WinnerU /= Username]),
								Message = "game_over " ++ Username ++ "\n",
								wait ! {game_over, WinnerUsername},
								[gen_tcp:send(Sock,list_to_binary(Message)) || Sock <- Socket],
                 				ranking ! {game_over_add_score, Username, WinnerUsername, Score, Score*2},
                 				ranking ! {game_over_add_level, WinnerUsername},
                 				[H | T] = Socket,
                 				Socket1 = H,
                 				Socket2 = hd(T),
                 				ranking ! {request_level, Socket1, Socket2, WinnerUsername, Username},
                 				ranking ! {request_top_score, Socket1, Socket2},
                 				ranking ! {request_top_level, Socket1, Socket2},
                 				[gen_tcp:send(Sock, list_to_binary("score_info " ++ WinnerUsername ++ " "
                 					++ integer_to_list(Score*2) ++  " " ++ Username ++ " "
                 					++ integer_to_list(Score) ++ "\n")) || Sock <- Socket],
              					From ! {repeat},
              					notifyRed ! stop,
              					state(NumGameRoom,#{},[],#{},#{},#{})
              end

		end.

		

create_red_monster(GRoom) ->
	receive
		{red_monster,From} ->
		io:format("Create Red Monster state here ~n"),
			GRoom ! {red_create,self()},
			From ! {repeat}
	end,
	create_red_monster(GRoom).

notify_red(Red) ->
	timer:send_after(10000,Red,{red_monster,self()}),
	io:format("send after 10000 here ~n"),
	receive
		{repeat} -> notify_red(Red);
		stop -> none
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
	{Username,{Speed,Dir,X,Y,H,W,Fe,Le,Re}} = Head,
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
	{Username,{Speed, Dir, XU, YU, HU, WU,Fe,Le,Re}} = Head,
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
	{Username,{Speed, Dir, XU, YU, HU, WU,Fe,Le,Re}} = Head,
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

charge_time_energy(Username,Energy,Online) ->
      case maps:is_key(Username,Online) of
      	false -> {failure};
      	true ->
      		{Speed, Dir, X, Y, H, W,Fe,Le,Re} = maps:get(Username,Online),
        case Energy of
        	"Fe" ->
          	if
         	 Fe == 100 -> {full};
          	 Fe < 100 -> 
            	NewOnline = maps:update(Username,{Speed, Dir, X, Y, H, W,Fe+5,Le,Re},Online),
            	Message = "charge " ++ Username ++ " " ++ integer_to_list(Le) ++ " " ++integer_to_list(Fe+5) ++ " " ++ integer_to_list(Re) ++ "\n",
            	{NewOnline,Message}
            end;
            "Le" ->
          	if
         	 Le == 100 -> {full};
          	 Le < 100 -> 
            	NewOnline = maps:update(Username,{Speed, Dir, X, Y, H, W,Fe,Le+5,Re},Online),
            	Message = "charge " ++ Username ++ " " ++ integer_to_list(Le+5) ++ " " ++integer_to_list(Fe) ++ " " ++ integer_to_list(Re) ++ "\n",
            	{NewOnline,Message}
            end;
            "Re" ->
          	if
         	 Re == 100 -> {full};
          	 Re < 100 -> 
            	NewOnline = maps:update(Username,{Speed, Dir, X, Y, H, W,Fe,Le,Re+5},Online),
            	Message = "charge " ++ Username ++ " " ++ integer_to_list(Le) ++ " " ++integer_to_list(Fe) ++ " " ++ integer_to_list(Re+5) ++ "\n",
            	{NewOnline,Message}
            end
          end
  	end.