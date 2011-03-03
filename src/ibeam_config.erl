%%%-------------------------------------------------------------------
%%% @author Justin Kirby <jkirby@voalte.com>
%%% @copyright (C) 2011 Justin Kirby
%%% @end
%%%
%%%-------------------------------------------------------------------


-module(ibeam_config).

-export([set_global/2,
	 get_global/2,
	 get_global/1,
	 get_modules/0
	 ]).

-include("ibeam.hrl").

	 


set_global(mods,Value) ->
    Mods = build_module_list("",Value),
    application:set_env(ibeam,mods,Mods);
set_global(Key,Value) when is_integer(Value) ->
    application:set_env(ibeam, Key, erlang:max(1,Value));
set_global(Key, Value) ->
    application:set_env(ibeam, Key, Value).


get_global(Key,Default) ->
    case application:get_env(ibeam, Key) of
	undefined ->
	    Default;
	{ok,Value} ->
	    Value
    end.

get_global(Key) ->
    get_global(Key,undefined).

get_modules() ->
    Keys = [base_mods,mods],
    get_modules(Keys,[]).

get_modules([],Acc) -> Acc;
get_modules([Key|Rest],Acc) ->
    Mods = get_global(Key,[]),
    get_modules(Rest,Acc++Mods).
    
    

%% set_module_list(Base,Value) ->
%%     Key = list_to_atom(atom_to_list(Base) ++ "_prefix"),
%%     Pre = get_global(Key),
%%     Mods = build_module_list(Pre,Value),
%%     application:set_env(ibeam,Base,Mods).

    
build_module_list(Prefix,Args) ->
    build_module_list(Prefix,string:tokens(Args,","),[]).
build_module_list(_Prefix,[],Mods) ->
    Mods;
build_module_list(Prefix,[Base|Rest],Mods) ->
    Mod = list_to_atom(Prefix++Base),
    build_module_list(Prefix,Rest,Mods++[Mod]).
    
