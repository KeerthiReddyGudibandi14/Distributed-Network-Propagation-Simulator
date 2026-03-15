-module(topology@line).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/topology/line.gleam").
-export([build/1]).

-file("src/topology/line.gleam", 3).
-spec build(integer()) -> list(list(integer())).
build(Num_nodes) ->
    _pipe = gleam@list:range(0, Num_nodes - 1),
    gleam@list:map(
        _pipe,
        fun(I) ->
            Left = case I > 0 of
                true ->
                    [I - 1];

                false ->
                    []
            end,
            Right = case I < (Num_nodes - 1) of
                true ->
                    [I + 1];

                false ->
                    []
            end,
            lists:append(Left, Right)
        end
    ).
