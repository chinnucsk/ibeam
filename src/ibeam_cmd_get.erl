%%%-------------------------------------------------------------------
%%% @author Justin Kirby <jkirby@voalte.com>
%%% @copyright (C) 2011 Justin Kirby
%%% @end
%%%
%%%-------------------------------------------------------------------


-module(ibeam_cmd_get).

-behaviour(ibeam_command).

-include("ibeam.hrl").

-export([command_help/0,
         deps/0,
         run/0,
         checkpoint/0
        ]).


command_help() ->
    Repos = ibeam_config:get_global(repos),
    HelpDesc = io_lib:format("Fetches erlang release tarball found in ~s/AppName/AppName-AppVsn.tar.gz    If url parameter is specified it will just fetch that.",[Repos]),
    {"get","name=AppName vsn=AppVsn url=http://FullUrl.com/path",HelpDesc}.

deps() -> [].

checkpoint() ->
    ibeam_checkpoint:store(?MODULE).


run() ->

    App = ibeam_config:get_global(name),
    Vsn = ibeam_config:get_global(vsn),

    RelName = App ++ "-" ++ Vsn,
    Dest = filename:join(["/tmp",RelName++".tar.gz"]),

    %% does the file exist?
    %% if so, then only download it again if force is used
    Skip = fetch_skip(Dest),
    Source = fetch_source(App,Vsn),

    case fetch_sh(Dest,Source,Skip) of
        {ok,Sh} ->
            ibeam_utils:sh(Sh,[]);
        ok -> ok
    end,

    ibeam_config:set_global(release_file,Dest),

    ok.

fetch_source(App,Vsn) ->
    case ibeam_config:get_global(local_file) of
        true ->
            {cp,?FMT("~s-~s.tar.gz",[App,Vsn])};
        _ ->
            {wget,fetch_url(App,Vsn)}
    end.


fetch_url(App,Vsn) ->
    case ibeam_config:get_global(url) of
        undefined ->
            UrlTemplate = ibeam_config:get_global(repos),
            ?FMT(UrlTemplate,[App,Vsn,App,Vsn]);
        GUrl -> GUrl
    end.

fetch_skip(Dest) ->
    case filelib:is_regular(Dest) of
        true ->
            case ibeam_config:get_global(force, false) of
                false ->
                    case ibeam_config:get_global(local_file, false) of
                        false ->
                            true;
                        true -> false
                    end;
                true -> false
            end;
        false -> false
    end.


fetch_sh(Dest,_Src,true) ->
    ?WARN("~s exists, skipping get~n",[Dest]),
    ok;
fetch_sh(Dest,{cp,Src},false) ->
    {ok,?FMT("cp -fR ~s ~s",[Src,Dest])};
fetch_sh(Dest,{wget,Src},false) ->
    {ok,?FMT("wget --no-check-certificate -nv -O ~s ~s",[Dest,Src])};
fetch_sh(_,Src,false) ->
    ?ABORT("~s is an invalid source~n",[Src]).
