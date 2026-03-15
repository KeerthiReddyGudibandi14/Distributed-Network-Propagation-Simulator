-module(util@list_ext).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/util/list_ext.gleam").
-export([get_at/2]).

-file("src/util/list_ext.gleam", 1).
-spec get_at_loop(list(YD), integer()) -> {ok, YD} | {error, nil}.
get_at_loop(List, Index) ->
    case {List, Index} of
        {[], _} ->
            {error, nil};

        {[X | _], 0} ->
            {ok, X};

        {[_ | Rest], _} ->
            get_at_loop(Rest, Index - 1)
    end.

-file("src/util/list_ext.gleam", 9).
-spec get_at(list(YH), integer()) -> {ok, YH} | {error, nil}.
get_at(List, Index) ->
    case Index < 0 of
        true ->
            {error, nil};

        false ->
            get_at_loop(List, Index)
    end.
