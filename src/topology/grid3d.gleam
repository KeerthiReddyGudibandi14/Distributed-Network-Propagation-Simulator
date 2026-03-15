import gleam/list

fn ceil_cuberoot_loop(n: Int, k: Int) -> Int {
  case k * k * k >= n {
    True -> k
    False -> ceil_cuberoot_loop(n, k + 1)
  }
}

fn ceil_cuberoot(n: Int) -> Int {
  ceil_cuberoot_loop(n, 1)
}

fn index(x: Int, y: Int, z: Int, side: Int) -> Int {
  x + y * side + z * side * side
}

pub fn build(num_nodes: Int) -> List(List(Int)) {
  let side = ceil_cuberoot(num_nodes)
  list.range(0, num_nodes - 1)
  |> list.map(fn(i) {
    let x = i % side
    let y = { i / side } % side
    let z = i / { side * side }
    let candidates = [
      index(x - 1, y, z, side),
      index(x + 1, y, z, side),
      index(x, y - 1, z, side),
      index(x, y + 1, z, side),
      index(x, y, z - 1, side),
      index(x, y, z + 1, side),
    ]
    candidates
    |> list.filter(fn(j) {
      case j >= 0 && j < num_nodes {
        True -> {
          let xj = j % side
          let yj = { j / side } % side
          let zj = j / { side * side }
          { xj == x && yj == y && { zj == z - 1 || zj == z + 1 } }
          || { xj == x && zj == z && { yj == y - 1 || yj == y + 1 } }
          || { yj == y && zj == z && { xj == x - 1 || xj == x + 1 } }
        }
        False -> False
      }
    })
  })
}
