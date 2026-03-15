-record(coord_state, {
    total :: integer(),
    terminated :: integer(),
    nodes :: list(gleam@erlang@process:subject(algo@gossip:gossip_msg())),
    waiter :: gleam@option:option(gleam@erlang@process:subject(nil)),
    failure :: types:failure()
}).
