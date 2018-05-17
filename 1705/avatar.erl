-module(avatar).
-export([generateAvatar/0,generate_green_monsters/0,generate_red_monsters/0]).

generateAvatar() ->
	{20, 60.0, rand:uniform(200)+0.0, 50.0, 50, 50,100}.

generate_green_monsters() -> %type 1 = green
	{15,rand:uniform(200)+0.0,200.0,50.0,50.0,1}.

generate_red_monsters() -> %type 0 = red
	{5,rand:uniform(700)+95.0,rand:uniform(500)+95.0,80.0,80.0,0}.
	%calculo: aleatorio + o tamanho superior à largura do monstro.