-record(register, {
    node_id :: integer(),
    subject :: gleam@erlang@process:subject(algo@gossip:gossip_msg())
}).
