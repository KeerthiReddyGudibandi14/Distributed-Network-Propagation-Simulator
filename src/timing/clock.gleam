import gleam/erlang/atom

@external(erlang, "erlang", "monotonic_time")
fn monotonic_time(unit: atom.Atom) -> Int

pub fn now_millis() -> Int {
  monotonic_time(atom.create("millisecond"))
}

pub fn elapsed_ms(start_ms: Int) -> Int {
  now_millis() - start_ms
}
