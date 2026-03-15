-module(debug_imp3d).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/debug_imp3d.gleam").
-export([main/0]).

-file("src/debug_imp3d.gleam", 24).
-spec print_neighbors(list(integer())) -> nil.
print_neighbors(Neighs) ->
    case Neighs of
        [] ->
            nil;

        [N] ->
            gleam_stdlib:print(erlang:integer_to_binary(N));

        [N@1 | Rest] ->
            gleam_stdlib:print(
                <<(erlang:integer_to_binary(N@1))/binary, ", "/utf8>>
            ),
            print_neighbors(Rest)
    end.

-file("src/debug_imp3d.gleam", 12).
-spec print_graph(list(list(integer())), integer()) -> nil.
print_graph(Graph, I) ->
    case Graph of
        [] ->
            nil;

        [Neighs | Rest] ->
            gleam_stdlib:print(
                <<<<"Node "/utf8, (erlang:integer_to_binary(I))/binary>>/binary,
                    ": ["/utf8>>
            ),
            print_neighbors(Neighs),
            gleam_stdlib:println(<<"]"/utf8>>),
            print_graph(Rest, I + 1)
    end.

-file("src/debug_imp3d.gleam", 6).
-spec main() -> nil.
main() ->
    Graph = topology@imp3d:build(8),
    gleam_stdlib:println(<<"imp3d topology for n=8:"/utf8>>),
    print_graph(Graph, 0).
