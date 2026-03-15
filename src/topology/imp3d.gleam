import gleam/dict
import gleam/list
import topology/grid3d
import util/list_ext
import util/random

fn add_extra_loop(
  base: List(List(Int)),
  num_nodes: Int,
  idx: Int,
  rng: random.Rng,
  acc: List(List(Int)),
) -> List(List(Int)) {
  case list_ext.get_at(base, idx) {
    Ok(neighs) -> {
      let limit = case num_nodes > 1 {
        True -> num_nodes - 1
        False -> 1
      }
      let #(r, rng2) = random.next_int(rng, limit)
      let candidate = case r >= idx {
        True -> r + 1
        False -> r
      }
      let extra = case list.contains(neighs, candidate) {
        True -> neighs
        False -> [candidate, ..neighs]
      }
      let acc2 = [extra, ..acc]
      case idx + 1 < num_nodes {
        True -> add_extra_loop(base, num_nodes, idx + 1, rng2, acc2)
        False -> list.reverse(acc2)
      }
    }
    Error(_) -> acc
  }
}

pub fn build(num_nodes: Int) -> List(List(Int)) {
  let base = grid3d.build(num_nodes)
  let rng0 = random.from_seed(42)
  let directed = add_extra_loop(base, num_nodes, 0, rng0, [])
  symmetrise(num_nodes, directed)
}

fn ensure_member(xs: List(Int), x: Int) -> List(Int) {
  case list.contains(xs, x) {
    True -> xs
    False -> [x, ..xs]
  }
}

fn add_edge(
  acc: dict.Dict(Int, List(Int)),
  a: Int,
  b: Int,
) -> dict.Dict(Int, List(Int)) {
  let xs = case dict.get(acc, a) {
    Ok(v) -> v
    Error(_) -> []
  }
  dict.insert(acc, a, ensure_member(xs, b))
}

fn symmetrise_loop(
  graph: List(List(Int)),
  i: Int,
  acc: dict.Dict(Int, List(Int)),
) -> dict.Dict(Int, List(Int)) {
  case graph {
    [] -> acc
    [neighs, ..rest] -> {
      let acc2 = symmetrise_edges(neighs, i, acc)
      symmetrise_loop(rest, i + 1, acc2)
    }
  }
}

fn symmetrise_edges(
  ns: List(Int),
  i: Int,
  acc: dict.Dict(Int, List(Int)),
) -> dict.Dict(Int, List(Int)) {
  case ns {
    [] -> acc
    [j, ..rest] -> {
      let acc1 = add_edge(acc, i, j)
      let acc2 = add_edge(acc1, j, i)
      symmetrise_edges(rest, i, acc2)
    }
  }
}

fn realise(
  num_nodes: Int,
  acc: dict.Dict(Int, List(Int)),
  i: Int,
  built: List(List(Int)),
) -> List(List(Int)) {
  case i < num_nodes {
    True -> {
      let xs = case dict.get(acc, i) {
        Ok(v) -> v
        Error(_) -> []
      }
      realise(num_nodes, acc, i + 1, [xs, ..built])
    }
    False -> list.reverse(built)
  }
}

fn symmetrise(num_nodes: Int, graph: List(List(Int))) -> List(List(Int)) {
  let acc = dict.new()
  let acc2 = symmetrise_loop(graph, 0, acc)
  realise(num_nodes, acc2, 0, [])
}
