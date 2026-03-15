-module(topology@grid3d).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/topology/grid3d.gleam").
-export([build/1]).

-file("src/topology/grid3d.gleam", 3).
-spec ceil_cuberoot_loop(integer(), integer()) -> integer().
ceil_cuberoot_loop(N, K) ->
    case ((K * K) * K) >= N of
        true ->
            K;

        false ->
            ceil_cuberoot_loop(N, K + 1)
    end.

-file("src/topology/grid3d.gleam", 10).
-spec ceil_cuberoot(integer()) -> integer().
ceil_cuberoot(N) ->
    ceil_cuberoot_loop(N, 1).

-file("src/topology/grid3d.gleam", 14).
-spec index(integer(), integer(), integer(), integer()) -> integer().
index(X, Y, Z, Side) ->
    (X + (Y * Side)) + ((Z * Side) * Side).

-file("src/topology/grid3d.gleam", 18).
-spec build(integer()) -> list(list(integer())).
build(Num_nodes) ->
    Side = ceil_cuberoot(Num_nodes),
    _pipe = gleam@list:range(0, Num_nodes - 1),
    gleam@list:map(
        _pipe,
        fun(I) ->
            X = case Side of
                0 -> 0;
                Gleam@denominator -> I rem Gleam@denominator
            end,
            Y = case Side of
                0 -> 0;
                Gleam@denominator@2 -> (case Side of
                    0 -> 0;
                    Gleam@denominator@1 -> I div Gleam@denominator@1
                end) rem Gleam@denominator@2
            end,
            Z = case (Side * Side) of
                0 -> 0;
                Gleam@denominator@3 -> I div Gleam@denominator@3
            end,
            Candidates = [index(X - 1, Y, Z, Side),
                index(X + 1, Y, Z, Side),
                index(X, Y - 1, Z, Side),
                index(X, Y + 1, Z, Side),
                index(X, Y, Z - 1, Side),
                index(X, Y, Z + 1, Side)],
            _pipe@1 = Candidates,
            gleam@list:filter(
                _pipe@1,
                fun(J) -> case (J >= 0) andalso (J < Num_nodes) of
                        true ->
                            Xj = case Side of
                                0 -> 0;
                                Gleam@denominator@4 -> J rem Gleam@denominator@4
                            end,
                            Yj = case Side of
                                0 -> 0;
                                Gleam@denominator@6 -> (case Side of
                                    0 -> 0;
                                    Gleam@denominator@5 -> J div Gleam@denominator@5
                                end) rem Gleam@denominator@6
                            end,
                            Zj = case (Side * Side) of
                                0 -> 0;
                                Gleam@denominator@7 -> J div Gleam@denominator@7
                            end,
                            ((((Xj =:= X) andalso (Yj =:= Y)) andalso ((Zj =:= (Z
                            - 1))
                            orelse (Zj =:= (Z + 1))))
                            orelse (((Xj =:= X) andalso (Zj =:= Z)) andalso ((Yj
                            =:= (Y - 1))
                            orelse (Yj =:= (Y + 1)))))
                            orelse (((Yj =:= Y) andalso (Zj =:= Z)) andalso ((Xj
                            =:= (X - 1))
                            orelse (Xj =:= (X + 1))));

                        false ->
                            false
                    end end
            )
        end
    ).
