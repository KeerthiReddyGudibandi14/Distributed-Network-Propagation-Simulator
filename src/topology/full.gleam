import gleam/list

pub fn build(num_nodes: Int) -> List(List(Int)) {
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) {
    list.range(0, num_nodes - 1)
    |> list.filter(fn(j) { j != i })
  })
}
