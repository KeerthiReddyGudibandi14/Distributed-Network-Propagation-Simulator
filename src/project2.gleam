import gleam/io
import gleam/int
import cli/argv
import types
import runner

fn usage() {
  io.println("Usage: project2 <numNodes> <topology:{full|3d|line|imp3d}> <algorithm:{gossip|push-sum}> [failure:{none|node|link-temp|link-perm}] [rate:0..1]")
}

pub fn main() -> Nil {
  let args = argv.arguments()
  case args {
    [num_str, topo_str, algo_str] -> {
      let num_res = int.parse(num_str)
      let topo_res = types.parse_topology(topo_str)
      let algo_res = types.parse_algorithm(algo_str)
      case num_res, topo_res, algo_res {
        Ok(num_nodes), Ok(topology), Ok(algorithm) -> runner.run(num_nodes, topology, algorithm)
        _, _, _ -> usage()
      }
    }
    [num_str, topo_str, algo_str, failure_str, rate_str] -> {
      let num_res = int.parse(num_str)
      let topo_res = types.parse_topology(topo_str)
      let algo_res = types.parse_algorithm(algo_str)
      let fail_res = types.parse_failure(failure_str, rate_str)
      case num_res, topo_res, algo_res, fail_res {
        Ok(num_nodes), Ok(topology), Ok(algorithm), Ok(failure) -> runner.run_with_failure(num_nodes, topology, algorithm, failure)
        _, _, _, _ -> usage()
      }
    }
    _ -> usage()
  }
}
