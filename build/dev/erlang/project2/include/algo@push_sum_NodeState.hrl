-record(node_state, {
    id :: integer(),
    neighbors :: list(gleam@erlang@process:subject(algo@push_sum:p_s_msg())),
    s :: float(),
    w :: float(),
    ratio :: float(),
    stable :: integer(),
    rng :: util@random:rng(),
    coord :: gleam@erlang@process:subject(algo@push_sum:coord_msg()),
    failure :: types:failure(),
    alive :: boolean(),
    self_subject :: gleam@erlang@process:subject(algo@push_sum:p_s_msg())
}).
