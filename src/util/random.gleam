import gleam/int

pub type Rng {
  Rng(seed: Int)
}

pub fn from_seed(seed: Int) -> Rng {
  Rng(seed: seed)
}

pub fn next_int(rng: Rng, max_exclusive: Int) -> #(Int, Rng) {
  let next = { rng.seed * 1103515245 + 12345 } % 2147483647
  let value = next % max_exclusive
  #(value, Rng(seed: next))
}

pub fn next_float(rng: Rng) -> #(Float, Rng) {
  let #(i, rng2) = next_int(rng, 2147483647)
  let f = int.to_float(i) /. 2147483647.0
  #(f, rng2)
}
