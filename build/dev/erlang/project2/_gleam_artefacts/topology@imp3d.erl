-module(topology@imp3d).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/topology/imp3d.gleam").
-export([build/1]).

-file("src/topology/imp3d.gleam", 7).
-spec add_extra_loop(
    list(list(integer())),
    integer(),
    integer(),
    util@random:rng(),
    list(list(integer()))
) -> list(list(integer())).
add_extra_loop(Base, Num_nodes, Idx, Rng, Acc) ->
    case util@list_ext:get_at(Base, Idx) of
        {ok, Neighs} ->
            Limit = case Num_nodes > 1 of
                true ->
                    Num_nodes - 1;

                false ->
                    1
            end,
            {R, Rng2} = util@random:next_int(Rng, Limit),
            Candidate = case R >= Idx of
                true ->
                    R + 1;

                false ->
                    R
            end,
            Extra = case gleam@list:contains(Neighs, Candidate) of
                true ->
                    Neighs;

                false ->
                    [Candidate | Neighs]
            end,
            Acc2 = [Extra | Acc],
            case (Idx + 1) < Num_nodes of
                true ->
                    add_extra_loop(Base, Num_nodes, Idx + 1, Rng2, Acc2);

                false ->
                    lists:reverse(Acc2)
            end;

        {error, _} ->
            Acc
    end.

-file("src/topology/imp3d.gleam", 46).
-spec ensure_member(list(integer()), integer()) -> list(integer()).
ensure_member(Xs, X) ->
    case gleam@list:contains(Xs, X) of
        true ->
            Xs;

        false ->
            [X | Xs]
    end.

-file("src/topology/imp3d.gleam", 53).
-spec add_edge(
    gleam@dict:dict(integer(), list(integer())),
    integer(),
    integer()
) -> gleam@dict:dict(integer(), list(integer())).
add_edge(Acc, A, B) ->
    Xs = case gleam_stdlib:map_get(Acc, A) of
        {ok, V} ->
            V;

        {error, _} ->
            []
    end,
    gleam@dict:insert(Acc, A, ensure_member(Xs, B)).

-file("src/topology/imp3d.gleam", 79).
-spec symmetrise_edges(
    list(integer()),
    integer(),
    gleam@dict:dict(integer(), list(integer()))
) -> gleam@dict:dict(integer(), list(integer())).
symmetrise_edges(Ns, I, Acc) ->
    case Ns of
        [] ->
            Acc;

        [J | Rest] ->
            Acc1 = add_edge(Acc, I, J),
            Acc2 = add_edge(Acc1, J, I),
            symmetrise_edges(Rest, I, Acc2)
    end.

-file("src/topology/imp3d.gleam", 65).
-spec symmetrise_loop(
    list(list(integer())),
    integer(),
    gleam@dict:dict(integer(), list(integer()))
) -> gleam@dict:dict(integer(), list(integer())).
symmetrise_loop(Graph, I, Acc) ->
    case Graph of
        [] ->
            Acc;

        [Neighs | Rest] ->
            Acc2 = symmetrise_edges(Neighs, I, Acc),
            symmetrise_loop(Rest, I + 1, Acc2)
    end.

-file("src/topology/imp3d.gleam", 94).
-spec realise(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    integer(),
    list(list(integer()))
) -> list(list(integer())).
realise(Num_nodes, Acc, I, Built) ->
    case I < Num_nodes of
        true ->
            Xs = case gleam_stdlib:map_get(Acc, I) of
                {ok, V} ->
                    V;

                {error, _} ->
                    []
            end,
            realise(Num_nodes, Acc, I + 1, [Xs | Built]);

        false ->
            lists:reverse(Built)
    end.

-file("src/topology/imp3d.gleam", 112).
-spec symmetrise(integer(), list(list(integer()))) -> list(list(integer())).
symmetrise(Num_nodes, Graph) ->
    Acc = maps:new(),
    Acc2 = symmetrise_loop(Graph, 0, Acc),
    realise(Num_nodes, Acc2, 0, []).

-file("src/topology/imp3d.gleam", 39).
-spec build(integer()) -> list(list(integer())).
build(Num_nodes) ->
    Base = topology@grid3d:build(Num_nodes),
    Rng0 = util@random:from_seed(42),
    Directed = add_extra_loop(Base, Num_nodes, 0, Rng0, []),
    symmetrise(Num_nodes, Directed).
