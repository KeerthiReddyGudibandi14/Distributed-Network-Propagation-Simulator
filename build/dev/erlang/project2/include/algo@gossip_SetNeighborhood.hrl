-record(set_neighborhood, {
    neighbors :: list(integer()),
    all :: list(gleam@erlang@process:subject(algo@gossip:gossip_msg()))
}).
