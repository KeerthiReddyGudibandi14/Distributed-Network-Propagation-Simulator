-module(util@random).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/util/random.gleam").
-export([from_seed/1, next_int/2, next_float/1]).
-export_type([rng/0]).

-type rng() :: {rng, integer()}.

-file("src/util/random.gleam", 7).
-spec from_seed(integer()) -> rng().
from_seed(Seed) ->
    {rng, Seed}.

-file("src/util/random.gleam", 11).
-spec next_int(rng(), integer()) -> {integer(), rng()}.
next_int(Rng, Max_exclusive) ->
    Next = ((erlang:element(2, Rng) * 1103515245) + 12345) rem 2147483647,
    Value = case Max_exclusive of
        0 -> 0;
        Gleam@denominator -> Next rem Gleam@denominator
    end,
    {Value, {rng, Next}}.

-file("src/util/random.gleam", 17).
-spec next_float(rng()) -> {float(), rng()}.
next_float(Rng) ->
    {I, Rng2} = next_int(Rng, 2147483647),
    F = erlang:float(I) / 2147483647.0,
    {F, Rng2}.
