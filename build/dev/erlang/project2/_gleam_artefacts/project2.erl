-module(project2).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/project2.gleam").
-export([main/0]).

-file("src/project2.gleam", 7).
-spec usage() -> nil.
usage() ->
    gleam_stdlib:println(
        <<"Usage: project2 <numNodes> <topology:{full|3d|line|imp3d}> <algorithm:{gossip|push-sum}> [failure:{none|node|link-temp|link-perm}] [rate:0..1]"/utf8>>
    ).

-file("src/project2.gleam", 11).
-spec main() -> nil.
main() ->
    Args = cli@argv:arguments(),
    case Args of
        [Num_str, Topo_str, Algo_str] ->
            Num_res = gleam_stdlib:parse_int(Num_str),
            Topo_res = types:parse_topology(Topo_str),
            Algo_res = types:parse_algorithm(Algo_str),
            case {Num_res, Topo_res, Algo_res} of
                {{ok, Num_nodes}, {ok, Topology}, {ok, Algorithm}} ->
                    runner:run(Num_nodes, Topology, Algorithm);

                {_, _, _} ->
                    usage()
            end;

        [Num_str@1, Topo_str@1, Algo_str@1, Failure_str, Rate_str] ->
            Num_res@1 = gleam_stdlib:parse_int(Num_str@1),
            Topo_res@1 = types:parse_topology(Topo_str@1),
            Algo_res@1 = types:parse_algorithm(Algo_str@1),
            Fail_res = types:parse_failure(Failure_str, Rate_str),
            case {Num_res@1, Topo_res@1, Algo_res@1, Fail_res} of
                {{ok, Num_nodes@1},
                    {ok, Topology@1},
                    {ok, Algorithm@1},
                    {ok, Failure}} ->
                    runner:run_with_failure(
                        Num_nodes@1,
                        Topology@1,
                        Algorithm@1,
                        Failure
                    );

                {_, _, _, _} ->
                    usage()
            end;

        _ ->
            usage()
    end.
