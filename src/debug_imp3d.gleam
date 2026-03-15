import gleam/int
import gleam/io
import gleam/list
import topology/imp3d

pub fn main() {
  let graph = imp3d.build(8)
  io.println("imp3d topology for n=8:")
  print_graph(graph, 0)
}

fn print_graph(graph: List(List(Int)), i: Int) {
  case graph {
    [] -> Nil
    [neighs, ..rest] -> {
      io.print("Node " <> int.to_string(i) <> ": [")
      print_neighbors(neighs)
      io.println("]")
      print_graph(rest, i + 1)
    }
  }
}

fn print_neighbors(neighs: List(Int)) {
  case neighs {
    [] -> Nil
    [n] -> io.print(int.to_string(n))
    [n, ..rest] -> {
      io.print(int.to_string(n) <> ", ")
      print_neighbors(rest)
    }
  }
}
