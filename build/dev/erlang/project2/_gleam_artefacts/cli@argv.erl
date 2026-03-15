-module(cli@argv).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/cli/argv.gleam").
-export([arguments/0]).

-file("src/cli/argv.gleam", 7).
-spec arguments() -> list(binary()).
arguments() ->
    gleam@list:map(
        init:get_plain_arguments(),
        fun unicode:characters_to_binary/1
    ).
