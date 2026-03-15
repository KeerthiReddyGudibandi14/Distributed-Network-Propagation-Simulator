-module(runner).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/runner.gleam").
-export([run_with_failure/4, run/3]).

-file("src/runner.gleam", 13).
-spec build_topology(integer(), types:topology()) -> list(list(integer())).
build_topology(N, T) ->
    case T of
        full ->
            topology@full:build(N);

        line ->
            topology@line:build(N);

        grid3_d ->
            topology@grid3d:build(N);

        imp3_d ->
            topology@imp3d:build(N)
    end.

-file("src/runner.gleam", 22).
-spec run_with_failure(
    integer(),
    types:topology(),
    types:algorithm(),
    types:failure()
) -> nil.
run_with_failure(N, T, A, F) ->
    Graph = build_topology(N, T),
    Start = timing@clock:now_millis(),
    Waiter = gleam@erlang@process:new_subject(),
    Shim = fun() ->
        case A of
            gossip ->
                algo@gossip:run(N, Graph, F);

            push_sum ->
                algo@push_sum:run(N, Graph, F)
        end,
        gleam@erlang@process:send(Waiter, nil)
    end,
    _ = proc_lib:spawn(Shim),
    Done = gleam@erlang@process:'receive'(Waiter, 120000),
    Elapsed = timing@clock:elapsed_ms(Start),
    case Done of
        {ok, _} ->
            gleam_stdlib:println(
                <<<<"Converged in "/utf8,
                        (erlang:integer_to_binary(Elapsed))/binary>>/binary,
                    " ms"/utf8>>
            );

        {error, _} ->
            gleam_stdlib:println(
                <<<<"Timed out after "/utf8,
                        (erlang:integer_to_binary(Elapsed))/binary>>/binary,
                    " ms"/utf8>>
            )
    end.

-file("src/runner.gleam", 52).
-spec run(integer(), types:topology(), types:algorithm()) -> nil.
run(N, T, A) ->
    run_with_failure(N, T, A, no_failure).
