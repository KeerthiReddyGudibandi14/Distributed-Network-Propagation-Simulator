-module(types_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/types_test.gleam").
-export([main/0, parses_topology_full_test/0, parses_topology_aliases_test/0, parses_algorithm_gossip_test/0, parses_algorithm_pushsum_test/0]).

-file("test/types_test.gleam", 5).
-spec main() -> nil.
main() ->
    gleeunit:main().

-file("test/types_test.gleam", 9).
-spec parses_topology_full_test() -> nil.
parses_topology_full_test() ->
    _pipe = types:parse_topology(<<"full"/utf8>>),
    gleeunit@should:equal(_pipe, {ok, full}).

-file("test/types_test.gleam", 14).
-spec parses_topology_aliases_test() -> nil.
parses_topology_aliases_test() ->
    _pipe = types:parse_topology(<<"3D"/utf8>>),
    gleeunit@should:equal(_pipe, {ok, grid3_d}).

-file("test/types_test.gleam", 19).
-spec parses_algorithm_gossip_test() -> nil.
parses_algorithm_gossip_test() ->
    _pipe = types:parse_algorithm(<<"gossip"/utf8>>),
    gleeunit@should:equal(_pipe, {ok, gossip}).

-file("test/types_test.gleam", 24).
-spec parses_algorithm_pushsum_test() -> nil.
parses_algorithm_pushsum_test() ->
    _pipe = types:parse_algorithm(<<"push-sum"/utf8>>),
    gleeunit@should:equal(_pipe, {ok, push_sum}).
