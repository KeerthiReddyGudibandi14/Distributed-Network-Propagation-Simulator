-module(algo@gossip).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/algo/gossip.gleam").
-export([run/3]).
-export_type([gossip_msg/0, coord_msg/0, coord_state/0, node_state/0]).

-type gossip_msg() :: {set_neighborhood,
        list(integer()),
        list(gleam@erlang@process:subject(gossip_msg()))} |
    rumor |
    tick |
    stop.

-type coord_msg() :: {register,
        integer(),
        gleam@erlang@process:subject(gossip_msg())} |
    {terminated, integer()} |
    {wait_for_all, gleam@erlang@process:subject(nil)}.

-type coord_state() :: {coord_state,
        integer(),
        integer(),
        list(gleam@erlang@process:subject(gossip_msg())),
        gleam@option:option(gleam@erlang@process:subject(nil)),
        types:failure()}.

-type node_state() :: {node_state,
        integer(),
        list(integer()),
        list(gleam@erlang@process:subject(gossip_msg())),
        integer(),
        util@random:rng(),
        gleam@erlang@process:subject(coord_msg()),
        types:failure(),
        boolean(),
        gleam@erlang@process:subject(gossip_msg()),
        boolean()}.

-file("src/algo/gossip.gleam", 86).
-spec register_nodes_with_coord_loop(
    list(gleam@erlang@process:subject(gossip_msg())),
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

-file("src/algo/gossip.gleam", 100).
-spec send_neighborhoods_loop(
    list(list(integer())),
    list(gleam@erlang@process:subject(gossip_msg())),
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

-file("src/algo/gossip.gleam", 129).
-spec coord_state(integer(), types:failure()) -> coord_state().
coord_state(Total, Failure) ->
    {coord_state, Total, 0, [], none, Failure}.

-file("src/algo/gossip.gleam", 139).
-spec handle_coord(coord_state(), coord_msg()) -> gleam@otp@actor:next(coord_state(), coord_msg()).
handle_coord(State, Msg) ->
    case Msg of
        {register, _, Subject} ->
            gleam@otp@actor:continue(
                {coord_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    [Subject | erlang:element(4, State)],
                    erlang:element(5, State),
                    erlang:element(6, State)}
            );

        {terminated, _} ->
            New_term = erlang:element(3, State) + 1,
            New_state = {coord_state,
                erlang:element(2, State),
                New_term,
                erlang:element(4, State),
                erlang:element(5, State),
                erlang:element(6, State)},
            case {New_term >= erlang:element(2, State),
                erlang:element(5, State)} of
                {true, {some, Reply}} ->
                    gleam@list:each(
                        erlang:element(4, New_state),
                        fun(Subject@1) ->
                            gleam@erlang@process:send(Subject@1, stop)
                        end
                    ),
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
                            erlang:element(4, State),
                            {some, Reply@1},
                            erlang:element(6, State)}
                    )
            end
    end.

-file("src/algo/gossip.gleam", 188).
-spec node_state(
    integer(),
    list(integer()),
    list(gleam@erlang@process:subject(gossip_msg())),
    integer(),
    util@random:rng(),
    gleam@erlang@process:subject(coord_msg()),
    types:failure(),
    boolean(),
    gleam@erlang@process:subject(gossip_msg()),
    boolean()
) -> node_state().
node_state(
    Id_,
    Neighbors_,
    All_,
    Heard_,
    Rng_,
    Coord_,
    Failure_,
    Alive_,
    Self_subject_,
    Announced_
) ->
    {node_state,
        Id_,
        Neighbors_,
        All_,
        Heard_,
        Rng_,
        Coord_,
        Failure_,
        Alive_,
        Self_subject_,
        Announced_}.

-file("src/algo/gossip.gleam", 214).
-spec should_drop_or_die(node_state()) -> {boolean(), node_state()}.
should_drop_or_die(State) ->
    case erlang:element(8, State) of
        no_failure ->
            {false, State};

        {node_death, Rate} ->
            {P, Rng2} = util@random:next_float(erlang:element(6, State)),
            case P =< Rate of
                true ->
                    {true,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            Rng2,
                            erlang:element(7, State),
                            erlang:element(8, State),
                            false,
                            erlang:element(10, State),
                            erlang:element(11, State)}};

                false ->
                    {false,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            Rng2,
                            erlang:element(7, State),
                            erlang:element(8, State),
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State)}}
            end;

        {link_temporary, Rate@1} ->
            {P@1, Rng2@1} = util@random:next_float(erlang:element(6, State)),
            {P@1 =< Rate@1,
                {node_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    erlang:element(4, State),
                    erlang:element(5, State),
                    Rng2@1,
                    erlang:element(7, State),
                    erlang:element(8, State),
                    erlang:element(9, State),
                    erlang:element(10, State),
                    erlang:element(11, State)}};

        {link_permanent, Rate@2} ->
            {P@2, Rng2@2} = util@random:next_float(erlang:element(6, State)),
            case P@2 =< Rate@2 of
                true ->
                    {true,
                        {node_state,
                            erlang:element(2, State),
                            [],
                            erlang:element(4, State),
                            erlang:element(5, State),
                            Rng2@2,
                            erlang:element(7, State),
                            erlang:element(8, State),
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State)}};

                false ->
                    {false,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            Rng2@2,
                            erlang:element(7, State),
                            erlang:element(8, State),
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State)}}
            end
    end.

-file("src/algo/gossip.gleam", 238).
-spec pick_neighbor(node_state()) -> {gleam@option:option(gleam@erlang@process:subject(gossip_msg())),
    node_state()}.
pick_neighbor(State) ->
    case erlang:element(3, State) of
        [] ->
            {none, State};

        _ ->
            Count = erlang:length(erlang:element(3, State)),
            {Idx_in_neighs, Rng2} = util@random:next_int(
                erlang:element(6, State),
                Count
            ),
            case util@list_ext:get_at(erlang:element(3, State), Idx_in_neighs) of
                {ok, Neighbor_id} ->
                    case util@list_ext:get_at(
                        erlang:element(4, State),
                        Neighbor_id
                    ) of
                        {ok, Subj} ->
                            {{some, Subj},
                                {node_state,
                                    erlang:element(2, State),
                                    erlang:element(3, State),
                                    erlang:element(4, State),
                                    erlang:element(5, State),
                                    Rng2,
                                    erlang:element(7, State),
                                    erlang:element(8, State),
                                    erlang:element(9, State),
                                    erlang:element(10, State),
                                    erlang:element(11, State)}};

                        {error, _} ->
                            {none,
                                {node_state,
                                    erlang:element(2, State),
                                    erlang:element(3, State),
                                    erlang:element(4, State),
                                    erlang:element(5, State),
                                    Rng2,
                                    erlang:element(7, State),
                                    erlang:element(8, State),
                                    erlang:element(9, State),
                                    erlang:element(10, State),
                                    erlang:element(11, State)}}
                    end;

                {error, _} ->
                    {none,
                        {node_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            erlang:element(5, State),
                            Rng2,
                            erlang:element(7, State),
                            erlang:element(8, State),
                            erlang:element(9, State),
                            erlang:element(10, State),
                            erlang:element(11, State)}}
            end
    end.

-file("src/algo/gossip.gleam", 258).
-spec handle_node(node_state(), gossip_msg()) -> gleam@otp@actor:next(node_state(), gossip_msg()).
handle_node(State, Msg) ->
    case Msg of
        {set_neighborhood, Neighs, All} ->
            gleam@otp@actor:continue(
                {node_state,
                    erlang:element(2, State),
                    Neighs,
                    All,
                    erlang:element(5, State),
                    erlang:element(6, State),
                    erlang:element(7, State),
                    erlang:element(8, State),
                    erlang:element(9, State),
                    erlang:element(10, State),
                    erlang:element(11, State)}
            );

        rumor ->
            case erlang:element(9, State) of
                false ->
                    gleam@otp@actor:stop();

                true ->
                    {Drop_or_die, State2} = should_drop_or_die(State),
                    case Drop_or_die of
                        true ->
                            gleam@otp@actor:continue(State2);

                        false ->
                            New_heard = erlang:element(5, State2) + 1,
                            case New_heard =:= 1 of
                                true ->
                                    gleam@erlang@process:send(
                                        erlang:element(10, State2),
                                        tick
                                    );

                                false ->
                                    nil
                            end,
                            State3 = {node_state,
                                erlang:element(2, State2),
                                erlang:element(3, State2),
                                erlang:element(4, State2),
                                New_heard,
                                erlang:element(6, State2),
                                erlang:element(7, State2),
                                erlang:element(8, State2),
                                erlang:element(9, State2),
                                erlang:element(10, State2),
                                erlang:element(11, State2)},
                            Final_state = case (New_heard >= 10) andalso not erlang:element(
                                11,
                                State3
                            ) of
                                true ->
                                    gleam@erlang@process:send(
                                        erlang:element(7, State3),
                                        {terminated, erlang:element(2, State3)}
                                    ),
                                    {node_state,
                                        erlang:element(2, State3),
                                        erlang:element(3, State3),
                                        erlang:element(4, State3),
                                        erlang:element(5, State3),
                                        erlang:element(6, State3),
                                        erlang:element(7, State3),
                                        erlang:element(8, State3),
                                        erlang:element(9, State3),
                                        erlang:element(10, State3),
                                        true};

                                false ->
                                    State3
                            end,
                            gleam@otp@actor:continue(Final_state)
                    end
            end;

        tick ->
            case erlang:element(9, State) of
                false ->
                    gleam@otp@actor:stop();

                true ->
                    {Maybe_target, Next_state} = pick_neighbor(State),
                    case Maybe_target of
                        {some, Target} ->
                            gleam@erlang@process:send(Target, rumor),
                            gleam@erlang@process:send(
                                erlang:element(10, Next_state),
                                tick
                            ),
                            gleam@otp@actor:continue(Next_state);

                        none ->
                            case not erlang:element(11, Next_state) of
                                true ->
                                    gleam@erlang@process:send(
                                        erlang:element(7, Next_state),
                                        {terminated,
                                            erlang:element(2, Next_state)}
                                    );

                                false ->
                                    nil
                            end,
                            gleam@otp@actor:stop()
                    end
            end;

        stop ->
            gleam@otp@actor:stop()
    end.

-file("src/algo/gossip.gleam", 49).
-spec start_nodes_loop(
    integer(),
    integer(),
    list(gleam@erlang@process:subject(gossip_msg())),
    gleam@erlang@process:subject(coord_msg()),
    types:failure()
) -> list(gleam@erlang@process:subject(gossip_msg())).
start_nodes_loop(Total, I, Acc, Coord, Failure) ->
    case I < Total of
        true ->
            Init = fun(Subject) ->
                State = node_state(
                    I,
                    [],
                    [],
                    0,
                    util@random:from_seed(12345 + I),
                    Coord,
                    Failure,
                    true,
                    Subject,
                    false
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
                                module => <<"algo/gossip"/utf8>>,
                                function => <<"start_nodes_loop"/utf8>>,
                                line => 76,
                                value => _assert_fail,
                                start => 1799,
                                'end' => 1934,
                                pattern_start => 1810,
                                pattern_end => 1821})
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

-file("src/algo/gossip.gleam", 23).
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
                        module => <<"algo/gossip"/utf8>>,
                        function => <<"run"/utf8>>,
                        line => 28,
                        value => _assert_fail,
                        start => 532,
                        'end' => 658,
                        pattern_start => 543,
                        pattern_end => 552})
    end,
    Coord_subject = erlang:element(3, Coord@1),
    Nodes = start_nodes_loop(Num_nodes, 0, [], Coord_subject, Failure),
    register_nodes_with_coord_loop(Nodes, 0, Coord_subject),
    send_neighborhoods_loop(Graph, Nodes, 0),
    case util@list_ext:get_at(Nodes, 0) of
        {ok, S} ->
            gleam@erlang@process:send(S, rumor);

        {error, _} ->
            nil
    end,
    Reply = gleam@erlang@process:new_subject(),
    gleam@erlang@process:send(Coord_subject, {wait_for_all, Reply}),
    _ = gleam@erlang@process:'receive'(Reply, 600000),
    nil.
