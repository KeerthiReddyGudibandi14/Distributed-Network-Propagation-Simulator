import gleam/list

pub fn build(num_nodes: Int) -> List(List(Int)) {
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) {
    let left = case i > 0 { True -> [i - 1] False -> [] }
    let right = case i < num_nodes - 1 { True -> [i + 1] False -> [] }
    list.append(left, right)
  })
}
