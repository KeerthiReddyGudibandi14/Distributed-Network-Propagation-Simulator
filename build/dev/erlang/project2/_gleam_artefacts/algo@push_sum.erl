-module(algo@push_sum).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/algo/push_sum.gleam").
-export([run/3]).
-export_type([p_s_msg/0, coord_msg/0, coord_state/0, node_state/0]).

-type p_s_msg() :: {set_neighborhood,
        list(integer()),
        list(gleam@erlang@process:subject(p_s_msg()))} |
    {transfer, float(), float()} |
    tick |
    stop.

-type coord_msg() :: {register,
        integer(),
        gleam@erlang@process:subject(p_s_msg())} |
    {terminated, integer()} |
    {wait_for_all, gleam@erlang@process:subject(nil)}.

-type coord_state() :: {coord_state,
        integer(),
        integer(),
        gleam@option:option(gleam@erlang@process:subject(nil)),
        types:failure()}.

-type node_state() :: {node_state,
        integer(),
        list(gleam@erlang@process:subject(p_s_msg())),
        float(),
        float(),
        float(),
        integer(),
        util@random:rng(),
        gleam@erlang@process:subject(coord_msg()),
        types:failure(),
        boolean(),
        gleam@erlang@process:subject(p_s_msg())}.

-file("src/algo/push_sum.gleam", 24).
-spec map_ids_to_subjects(
    list(gleam@erlang@process:subject(p_s_msg())),
    list(integer())
) -> list(gleam@erlang@process:subject(p_s_msg())).
map_ids_to_subjects(All, Ids) ->
    case Ids of
        [] ->
            [];

        [I | Rest] ->
            Tail = map_ids_to_subjects(All, Rest),
            case util@list_ext:get_at(All, I) of
                {ok, S} ->
                    [S | Tail];

                {error, _} ->
                    Tail
            end
    end.

-file("src/algo/push_sum.gleam", 64).
-spec start_ticks(list(gleam@erlang@process:subject(p_s_msg()))) -> nil.
start_ticks(Nodes) ->
    case Nodes of
        [] ->
            nil;

        [S | Rest] ->
            gleam@erlang@process:send(S, tick),
            start_ticks(Rest)
    end.

-file("src/algo/push_sum.gleam", 112).
-spec register_nodes_with_coord_loop(
    list(gleam@erlang@process:subject(p_s_msg())),
    integer(),
    gleam@erlang@process:subject(coord_msg())
) -> nil.
register_nodes_with_coord_loop(Nodes, I, Coord) ->
    case Nodes of
        [] ->
            nil;

        [S | Rest] ->
            gleam@erlang@process:send(Coord, {register, I, S}),
            register_nodes_with_coord_loop(Rest, I + 1, Coord)
    end.

-file("src/algo/push_sum.gleam", 126).
-spec send_neighborhoods_loop(
    list(list(integer())),
    list(gleam@erlang@process:subject(p_s_msg())),
    integer()
) -> nil.
send_neighborhoods_loop(Graph, Nodes, I) ->
    case Graph of
        [] ->
            nil;

        [Neighs | Rest] ->
            case util@list_ext:get_at(Nodes, I) of
                {ok, S} ->
                    gleam@erlang@process:send(
                        S,
                        {set_neighborhood, Neighs, Nodes}
                    );

                {error, _} ->
                    nil
            end,
            send_neighborhoods_loop(Rest, Nodes, I + 1)
    end.

-file("src/algo/push_sum.gleam", 152).
-spec coord_state(integer(), types:failure()) -> coord_state().
coord_state(Total, Failure) ->
    {coord_state, Total, 0, none, Failure}.

-file("src/algo/push_sum.gleam", 156).
-spec handle_coord(coord_state(), coord_msg()) -> gleam@otp@actor:next(coord_state(), coord_msg()).
handle_coord(State, Msg) ->
    case Msg of
        {register, _, _} ->
            gleam@otp@actor:continue(State);

        {terminated, _} ->
            New_term = erlang:element(3, State) + 1,
            New_state = {coord_state,
                erlang:element(2, State),
                New_term,
                erlang:element(4, State),
                erlang:element(5, State)},
            case {New_term >= erlang:element(2, State),
                erlang:element(4, State)} of
                {true, {some, Reply}} ->
                    gleam@erlang@process:send(Reply, nil),
                    gleam@otp@actor:stop();

                {_, _} ->
                    gleam@otp@actor:continue(New_state)
            end;

        {wait_for_all, Reply@1} ->
            case erlang:element(3, State) >= erlang:element(2, State) of
                true ->
                    gleam@erlang@process:send(Reply@1, nil),
                    gleam@otp@actor:stop();

                false ->
                    gleam@otp@actor:continue(
                        {coord_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            {some, Reply@1},
                            erlang:element(5, State)}
                    )
            end
    end.

-file("src/algo/push_sum.gleam", 201).
-spec node_state(
    integer(),
    list(gleam@erlang@process:subject(p_s_msg())),
    float(),
    float(),
    float(),
    integer(),
    util@random:rng(),
    gleam@erlang@process:subject(coord_msg()),
    types:failure(),
    boolean(),
    gleam@erlang@process:subject(p_s_msg())
) -> node_state().
node_state(
    Id_,
    Neighbors_,
    S_,
    W_,
    Ratio_,
    Stable_,
    Rng_,
    Coord_,
    Failure_,
    Alive_,
    Self_subject_
) ->
    {node_state,
        Id_,
        Neighbors_,
        S_,
        W_,
        Ratio_,
        Stable_,
        Rng_,
        Coord_,
        Failure_,
        Alive_,
        Self_subject_}.

-file("src/algo/push_sum.gleam", 229).
-spec should_drop_or_die(node_state()) -> {boolean(), node_state()}.
should_drop_or_die(State) ->
    case erlang:element(10, State) of
        no_failure ->
            {false, State};

        {node_death, Rate} ->
            {P, Rng2} = util@random:next_float(erlang:element(8, State)),
            case P =< Rate of
                true ->
                    {true,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            erlang:element(6, State),
                            erlang:element(7, State),
                            Rng2,
                            erlang:element(9, State),
                            erlang:element(10, State),
                            false,
                            erlang:element(12, State)}};

                false ->
                    {false,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            erlang:element(6, State),
                            erlang:element(7, State),
                            Rng2,
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State),
                            erlang:element(12, State)}}
            end;

        {link_temporary, Rate@1} ->
            {P@1, Rng2@1} = util@random:next_float(erlang:element(8, State)),
            {P@1 =< Rate@1,
                {node_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    erlang:element(4, State),
                    erlang:element(5, State),
                    erlang:element(6, State),
                    erlang:element(7, State),
                    Rng2@1,
                    erlang:element(9, State),
                    erlang:element(10, State),
                    erlang:element(11, State),
                    erlang:element(12, State)}};

        {link_permanent, Rate@2} ->
            {P@2, Rng2@2} = util@random:next_float(erlang:element(8, State)),
            case P@2 =< Rate@2 of
                true ->
                    {true,
                        {node_state,
                            erlang:element(2, State),
                            [],
                            erlang:element(4, State),
                            erlang:element(5, State),
                            erlang:element(6, State),
                            erlang:element(7, State),
                            Rng2@2,
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State),
                            erlang:element(12, State)}};

                false ->
                    {false,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            erlang:element(6, State),
                            erlang:element(7, State),
                            Rng2@2,
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State),
                            erlang:element(12, State)}}
            end
    end.

-file("src/algo/push_sum.gleam", 253).
-spec pick_neighbor(node_state()) -> {gleam@option:option(gleam@erlang@process:subject(p_s_msg())),
    node_state()}.
pick_neighbor(State) ->
    case erlang:element(3, State) of
        [] ->
            {none, State};

        _ ->
            Count = erlang:length(erlang:element(3, State)),
            {Idx_in_neighs, Rng2} = util@random:next_int(
                erlang:element(8, State),
                Count
            ),
            case util@list_ext:get_at(erlang:element(3, State), Idx_in_neighs) of
                {ok, Subj} ->
                    {{some, Subj},
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            erlang:element(6, State),
                            erlang:element(7, State),
                            Rng2,
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State),
                            erlang:element(12, State)}};

                {error, _} ->
                    {none,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            erlang:element(6, State),
                            erlang:element(7, State),
                            Rng2,
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State),
                            erlang:element(12, State)}}
            end
    end.

-file("src/algo/push_sum.gleam", 269).
-spec handle_node(node_state(), p_s_msg()) -> gleam@otp@actor:next(node_state(), p_s_msg()).
handle_node(State, Msg) ->
    case Msg of
        {set_neighborhood, Neighs, All} ->
            gleam@otp@actor:continue(
                {node_state,
                    erlang:element(2, State),
                    map_ids_to_subjects(All, Neighs),
                    erlang:element(4, State),
                    erlang:element(5, State),
                    erlang:element(6, State),
                    erlang:element(7, State),
                    erlang:element(8, State),
                    erlang:element(9, State),
                    erlang:element(10, State),
                    erlang:element(11, State),
                    erlang:element(12, State)}
            );

        tick ->
            case erlang:element(11, State) of
                false ->
                    gleam@otp@actor:stop();

                true ->
                    {Drop_or_die, State2} = should_drop_or_die(State),
                    case erlang:element(11, State2) =:= false of
                        true ->
                            gleam@erlang@process:send(
                                erlang:element(9, State2),
                                {terminated, erlang:element(2, State2)}
                            ),
                            gleam@otp@actor:stop();

                        false ->
                            case Drop_or_die of
                                true ->
                                    gleam@erlang@process:send(
                                        erlang:element(12, State2),
                                        tick
                                    ),
                                    gleam@otp@actor:continue(State2);

                                false ->
                                    S1 = erlang:element(4, State2),
                                    W1 = erlang:element(5, State2),
                                    Ratio1 = case W1 of
                                        +0.0 -> +0.0;
                                        -0.0 -> -0.0;
                                        Gleam@denominator -> S1 / Gleam@denominator
                                    end,
                                    Delta = gleam@float:absolute_value(
                                        erlang:element(6, State2) - Ratio1
                                    ),
                                    Stable1 = case Delta =< 1.0e-10 of
                                        true ->
                                            erlang:element(7, State2) + 1;

                                        false ->
                                            0
                                    end,
                                    case Stable1 >= 3 of
                                        true ->
                                            gleam@erlang@process:send(
                                                erlang:element(9, State2),
                                                {terminated,
                                                    erlang:element(2, State2)}
                                            ),
                                            gleam@otp@actor:stop();

                                        false ->
                                            S2 = S1 / 2.0,
                                            W2 = W1 / 2.0,
                                            {Maybe_target, Next_state} = pick_neighbor(
                                                {node_state,
                                                    erlang:element(2, State2),
                                                    erlang:element(3, State2),
                                                    S2,
                                                    W2,
                                                    Ratio1,
                                                    Stable1,
                                                    erlang:element(8, State2),
                                                    erlang:element(9, State2),
                                                    erlang:element(10, State2),
                                                    erlang:element(11, State2),
                                                    erlang:element(12, State2)}
                                            ),
                                            case Maybe_target of
                                                {some, Target} ->
                                                    gleam@erlang@process:send(
                                                        Target,
                                                        {transfer, S2, W2}
                                                    ),
                                                    gleam@erlang@process:send(
                                                        erlang:element(
                                                            12,
                                                            Next_state
                                                        ),
                                                        tick
                                                    ),
                                                    gleam@otp@actor:continue(
                                                        Next_state
                                                    );

                                                none ->
                                                    gleam@erlang@process:send(
                                                        erlang:element(
                                                            9,
                                                            Next_state
                                                        ),
                                                        {terminated,
                                                            erlang:element(
                                                                2,
                                                                Next_state
                                                            )}
                                                    ),
                                                    gleam@otp@actor:stop()
                                            end
                                    end
                            end
                    end
            end;

        {transfer, Ds, Dw} ->
            New_state = {node_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State) + Ds,
                erlang:element(5, State) + Dw,
                erlang:element(6, State),
                erlang:element(7, State),
                erlang:element(8, State),
                erlang:element(9, State),
                erlang:element(10, State),
                erlang:element(11, State),
                erlang:element(12, State)},
            gleam@erlang@process:send(erlang:element(12, New_state), tick),
            gleam@otp@actor:continue(New_state);

        stop ->
            gleam@otp@actor:stop()
    end.

-file("src/algo/push_sum.gleam", 74).
-spec start_nodes_loop(
    integer(),
    integer(),
    list(gleam@erlang@process:subject(p_s_msg())),
    gleam@erlang@process:subject(coord_msg()),
    types:failure()
) -> list(gleam@erlang@process:subject(p_s_msg())).
start_nodes_loop(Total, I, Acc, Coord, Failure) ->
    case I < Total of
        true ->
            Init = fun(Subject) ->
                State = node_state(
                    I,
                    [],
                    erlang:float(I),
                    1.0,
                    +0.0,
                    0,
                    util@random:from_seed(9999 + I),
                    Coord,
                    Failure,
                    true,
                    Subject
                ),
                _pipe = gleam@otp@actor:initialised(State),
                _pipe@1 = gleam@otp@actor:returning(_pipe, Subject),
                {ok, _pipe@1}
            end,
            Started@1 = case begin
                _pipe@2 = gleam@otp@actor:new_with_initialiser(1000, Init),
                _pipe@3 = gleam@otp@actor:on_message(_pipe@2, fun handle_node/2),
                gleam@otp@actor:start(_pipe@3)
            end of
                {ok, Started} -> Started;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"algo/push_sum"/utf8>>,
                                function => <<"start_nodes_loop"/utf8>>,
                                line => 102,
                                value => _assert_fail,
                                start => 2306,
                                'end' => 2441,
                                pattern_start => 2317,
                                pattern_end => 2328})
            end,
            start_nodes_loop(
                Total,
                I + 1,
                [erlang:element(3, Started@1) | Acc],
                Coord,
                Failure
            );

        false ->
            lists:reverse(Acc)
    end.

-file("src/algo/push_sum.gleam", 40).
-spec run(integer(), list(list(integer())), types:failure()) -> nil.
run(Num_nodes, Graph, Failure) ->
    Coord@1 = case begin
        _pipe = gleam@otp@actor:new(coord_state(Num_nodes, Failure)),
        _pipe@1 = gleam@otp@actor:on_message(_pipe, fun handle_coord/2),
        gleam@otp@actor:start(_pipe@1)
    end of
        {ok, Coord} -> Coord;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"algo/push_sum"/utf8>>,
                        function => <<"run"/utf8>>,
                        line => 45,
                        value => _assert_fail,
                        start => 886,
                        'end' => 1012,
                        pattern_start => 897,
                        pattern_end => 906})
    end,
    Coord_subject = erlang:element(3, Coord@1),
    Nodes = start_nodes_loop(Num_nodes, 0, [], Coord_subject, Failure),
    register_nodes_with_coord_loop(Nodes, 0, Coord_subject),
    send_neighborhoods_loop(Graph, Nodes, 0),
    start_ticks(Nodes),
    Reply = gleam@erlang@process:new_subject(),
    gleam@erlang@process:send(Coord_subject, {wait_for_all, Reply}),
    _ = gleam@erlang@process:'receive'(Reply, 600000),
    nil.
