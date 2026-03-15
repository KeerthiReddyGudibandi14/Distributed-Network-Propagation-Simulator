-record(node_state, {
    id :: integer(),
    neighbors :: list(integer()),
    all :: list(gleam@erlang@process:subject(algo@gossip:gossip_msg())),
    heard :: integer(),
    rng :: util@random:rng(),
    coord :: gleam@erlang@process:subject(algo@gossip:coord_msg()),
    failure :: types:failure(),
    alive :: boolean(),
    self_subject :: gleam@erlang@process:subject(algo@gossip:gossip_msg()),
    announced :: boolean()
}).
