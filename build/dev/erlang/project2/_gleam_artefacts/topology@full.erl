-module(topology@full).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/topology/full.gleam").
-export([build/1]).

-file("src/topology/full.gleam", 3).
-spec build(integer()) -> list(list(integer())).
build(Num_nodes) ->
    _pipe = gleam@list:range(0, Num_nodes - 1),
    gleam@list:map(
        _pipe,
        fun(I) -> _pipe@1 = gleam@list:range(0, Num_nodes - 1),
            gleam@list:filter(_pipe@1, fun(J) -> J /= I end) end
    ).
