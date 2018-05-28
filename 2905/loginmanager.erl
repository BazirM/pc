-module(loginmanager).
-compile(export_all).

%Parsing:
%String:tokens("hello world"," ") -> ["hello","world"];

%primeiro map: users, segundo map: users online
%#1ºMap: {Username => {Passwd,_}} | 2º Map: {Username => Socket}
start() ->
	Pid = spawn(?MODULE, management,[#{},#{}]),
	register(?MODULE,Pid).

%N número de utilizadores logados
create_account(Username,Passwd,Socket) ->
	?MODULE ! {create,Username,Passwd,self(),Socket},
	receive
		{?MODULE,ok,N} -> {ok,N};
		{?MODULE,user_exists} -> {user_exists}
	end.

close_account(Username,Passwd,Socket) ->
	?MODULE ! {close,Username,Passwd,self(),Socket},
	receive
		{?MODULE, Result} -> Result
	end.

login(Username,Passwd,Socket) ->
	?MODULE ! {login,Username,Passwd,self(),Socket},
	receive
		{?MODULE,ok,N} -> {ok,N};
		{?MODULE,invalid} -> invalid
	end.

logout(Username,Passwd,Socket) ->
	?MODULE ! {logout,Username,Passwd,self(),Socket},
	receive
		{?MODULE,Result} -> Result
	end.

online() ->
	?MODULE ! {online,self()},
	receive
		{?MODULE,Result,Result2} -> {Result,Result2}
	end.

logged(Socket) ->
	?MODULE ! {logged,self(),Socket},
	receive
		{?MODULE, Result} -> Result
	end.

find_by_value(Value, Map) ->
  List = maps:to_list(Map),
  Result = lists:filter(fun({_, V}) -> V == Value end, List),
  case Result of
    [] -> error;
    _ -> hd(Result)
  end.

management(Users,Onlines) ->
	receive
		{create,Username,Passwd,From,Socket} ->
			case maps:find(Username,Users) of
				error -> From ! {?MODULE,ok, maps:size(Onlines)},
					U = maps:put(Username,{Passwd,false},Users),
					management(U,Onlines);
				_ -> From ! {?MODULE,user_exists}, management(Users,Onlines)
				
			end;
		{close,Username,Passwd,From,Socket} ->
			case maps:find(Username,Users) of
				{ok,{Passwd,_}} -> From ! {?MODULE,ok},
									O = maps:remove(Username,Onlines),
									U = maps:remove(Username,Users),
									management(U,O);
				_ -> From ! {?MODULE,invalid},
					management(Users,Onlines)
			end;
		{login,Username,Passwd,From,Socket} ->
			case maps:find(Username,Users) of
				{ok,{Passwd,_}} -> From ! {?MODULE,ok, maps:size(Onlines)+1 },
								O = maps:put(Username,Socket,Onlines),
								U = maps:update(Username,{Passwd,true},Users),
								management(U,O);
				_ -> From ! {?MODULE,invalid},
					management(Users,Onlines)
			end;
		{logout,Username,Passwd,From,Socket} ->
			case maps:find(Username,Users) of
				{ok,{Passwd,true}} -> From ! {?MODULE,ok},
									O = maps:remove(Username,Onlines),
									U = maps:update(Username,{Passwd,false},Users),
									management(U,O);
				_ -> management(Users,Onlines)
			end;
		{online,From} ->
			From ! {?MODULE,[Username || {Username,{_,true}} <- maps:to_list(Users)], Onlines},
			management(Users, Onlines);
		
		{logged,From,Socket} ->
			case find_by_value(Socket,Onlines) of
				{U,_} -> From ! {?MODULE,U};
				error -> From ! {?MODULE,notfound}
			end,
			management(Users,Onlines)
	end.


