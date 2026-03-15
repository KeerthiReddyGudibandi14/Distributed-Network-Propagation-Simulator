-module(types).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/types.gleam").
-export([parse_topology/1, parse_algorithm/1, parse_failure/2]).
-export_type([topology/0, algorithm/0, failure/0]).

-type topology() :: full | grid3_d | line | imp3_d.

-type algorithm() :: gossip | push_sum.

-type failure() :: no_failure |
    {node_death, float()} |
    {link_temporary, float()} |
    {link_permanent, float()}.

-file("src/types.gleam", 11).
-spec parse_topology(binary()) -> {ok, topology()} | {error, binary()}.
parse_topology(Input) ->
    Lowered = string:lowercase(Input),
    case Lowered of
        <<"full"/utf8>> ->
            {ok, full};

        <<"3d"/utf8>> ->
            {ok, grid3_d};

        <<"grid3d"/utf8>> ->
            {ok, grid3_d};

        <<"line"/utf8>> ->
            {ok, line};

        <<"imp3d"/utf8>> ->
            {ok, imp3_d};

        Other ->
            {error, <<"Unknown topology: "/utf8, Other/binary>>}
    end.

-file("src/types.gleam", 28).
-spec parse_algorithm(binary()) -> {ok, algorithm()} | {error, binary()}.
parse_algorithm(Input) ->
    Lowered = string:lowercase(Input),
    case Lowered of
        <<"gossip"/utf8>> ->
            {ok, gossip};

        <<"push-sum"/utf8>> ->
            {ok, push_sum};

        <<"push_sum"/utf8>> ->
            {ok, push_sum};

        <<"pushsum"/utf8>> ->
            {ok, push_sum};

        Other ->
            {error, <<"Unknown algorithm: "/utf8, Other/binary>>}
    end.

-file("src/types.gleam", 46).
-spec parse_failure(binary(), binary()) -> {ok, failure()} | {error, binary()}.
parse_failure(Model, Rate_s) ->
    M = string:lowercase(Model),
    R = gleam_stdlib:parse_float(Rate_s),
    case {M, R} of
        {<<"none"/utf8>>, _} ->
            {ok, no_failure};

        {<<"node"/utf8>>, {ok, Rate}} ->
            {ok, {node_death, Rate}};

        {<<"link-temp"/utf8>>, {ok, Rate@1}} ->
            {ok, {link_temporary, Rate@1}};

        {<<"link-perm"/utf8>>, {ok, Rate@2}} ->
            {ok, {link_permanent, Rate@2}};

        {_, {error, _}} ->
            {error, <<"Invalid failure rate: "/utf8, Rate_s/binary>>};

        {Other, _} ->
            {error, <<"Unknown failure model: "/utf8, Other/binary>>}
    end.
