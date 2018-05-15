-module(avatar).
-export([generateAvatar/0,generate_green_monsters/0,generate_red_monsters/0]).

generateAvatar() ->
	{20, 60.0, rand:uniform(500)+0.0, 50.0, 50, 50}.

generate_green_monsters() -> %type 1 = green
	{15,rand:uniform(200)+0.0,200.0,50.0,50.0,1}.

generate_red_monsters() -> %type 0 = red
	{15,300.0,300.0,65.0,65.0,0}.
