-module(timing@clock).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/timing/clock.gleam").
-export([now_millis/0, elapsed_ms/1]).

-file("src/timing/clock.gleam", 6).
-spec now_millis() -> integer().
now_millis() ->
    erlang:monotonic_time(erlang:binary_to_atom(<<"millisecond"/utf8>>)).

-file("src/timing/clock.gleam", 10).
-spec elapsed_ms(integer()) -> integer().
elapsed_ms(Start_ms) ->
    now_millis() - Start_ms.
