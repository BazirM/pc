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
			++ " " ++ integer_to_list(W) ++ "\n"))
            || {Username,{Speed, Dir, X, Y, H, W}} <- PList]    
  end,

  case maps:to_list(GreenMonsters) of
  	[] -> skip;
  	GM ->
  		[gen_tcp:send(Socket,list_to_binary("add_green_monster " ++ integer_to_list(I) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n"))
                 || {I,{Speed,X,Y,H,W,Type}} <- GM]
    end,

  case maps:to_list(RedMonsters) of
  	[] -> skip;
  	RM ->
  		[gen_tcp:send(Socket,list_to_binary("add_red_monster " ++ integer_to_list(I) ++ " " ++ integer_to_list(Speed) ++ " " ++ float_to_list(X) 
                ++ " " ++ float_to_list(Y) ++ " " ++ float_to_list(H) ++ " " ++ float_to_list(W) ++ " " ++ integer_to_list(Type) ++ "\n"))
                 || {I,{Speed,X,Y,H,W,Type}} <- RM]
    end.
%Online #{Username => Avatar = ({Speed,Dir,X,Y,H,W})}
% GreenMonsters #{I => Monster = ({Speed,X,Y,H,W,Type})}
% RedMonsters
state(Online,Socket,GreenMonsters,RedMonsters) ->
	receive
		{online, add, Username} ->
			{Speed, Dir, X, Y, H, W} = generateAvatar(),
			%0 é o score
			Data = "online " ++ Username ++  " 0 " ++ integer_to_list(Speed) ++ " " ++ float_to_list(Dir)
			++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ " " ++ integer_to_list(H)
			++ " " ++ integer_to_list(W) ++ "\n",
			[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
			NewOnline = maps:put(Username, {Speed, Dir, X, Y, H, W},Online),
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
					{Speed, Dir, X, Y, H, W} = maps:get(Username,Online),
					O = maps:update(Username,{Speed, Dir-10, X, Y, H, W},Online),
					Data = "on_update_left " ++ Username ++ " " ++ float_to_list(Dir-10) ++ " " ++ "\n",
					[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
					state(O,Socket,GreenMonsters,RedMonsters)
			end;

		{right,Username} ->
			case maps:is_key(Username,Online) of
				false -> state(Online,Socket,GreenMonsters,RedMonsters);
				true ->
					{Speed, Dir, X, Y, H, W} = maps:get(Username,Online),
					O = maps:update(Username,{Speed, Dir+10, X, Y, H, W},Online),
					Data = "on_update_right " ++ Username ++ " " ++ float_to_list(Dir+10) ++ " " ++ "\n",
					[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
					state(O,Socket,GreenMonsters,RedMonsters)
			end;

		{front,Username} ->
			case maps:is_key(Username,Online) of
				false -> state(Online,Socket,GreenMonsters,RedMonsters);
				true -> {Speed, Dir, X, Y, H, W} = maps:get(Username,Online),
						Updated_X = (math:cos(Dir*math:pi()/180)*Speed) + X,
						Updated_Y = (math:sin(Dir*math:pi()/180)*Speed) + Y,
						O = maps:update(Username,{Speed, Dir, Updated_X, Updated_Y, H, W},Online),
						Data = "on_update_front " ++ Username ++ " " ++ float_to_list(Updated_X) ++ " " ++ float_to_list(Updated_Y) ++ " " ++ "\n",
						[gen_tcp:send(Sock,list_to_binary(Data)) || Sock <- Socket],
						state(O,Socket,GreenMonsters,RedMonsters)
			end;

		{generate_monsters} ->
				GM = maps:put(0,generate_green_monsters(),GreenMonsters),
				GM2 = maps:put(1,generate_green_monsters(),GM),
				RM = maps:put(0,generate_red_monsters(),RedMonsters),
				state(Online,Socket,GM2,RM);
		
		{monsters_upt,From} ->
			  GreenM = maps:to_list(GreenMonsters),
              [gen_tcp:send(Sock,list_to_binary("green_monster_upt " ++ integer_to_list(I) ++ " " ++ float_to_list(X) ++ " " 
                ++ float_to_list(Y) ++ " " ++ integer_to_list(Type) ++ "\n")) || Sock <- Socket, {I,{Speed,X,Y,H,W,Type}} <- GreenM],
              %Green_Updated = maps:update(0,{Speed,X+10,Y+10,H,W,Type},GreenMonsters),
              {Speed,X,Y,H,W,Type} = maps:get(0,GreenMonsters),
              {Speed2,X2,Y2,H2,W2,Type} = maps:get(1,GreenMonsters),
              Green_Updated = maps:update(0,{Speed,X+0.5,Y+0.5,H,W,Type},GreenMonsters),
              Green_Updated2 = maps:update(1,{Speed2,X2+0.7,Y2+0.7,H2,W2,Type},Green_Updated),
              From ! {repeat},
              state(Online,Socket,Green_Updated2,RedMonsters)
            
		end.
				
