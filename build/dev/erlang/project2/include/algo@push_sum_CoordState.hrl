-record(coord_state, {
    total :: integer(),
    terminated :: integer(),
    waiter :: gleam@option:option(gleam@erlang@process:subject(nil)),
    failure :: types:failure()
}).
