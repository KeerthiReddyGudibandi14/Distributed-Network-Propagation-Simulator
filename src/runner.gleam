import algo/gossip
import algo/push_sum
import gleam/erlang/process
import gleam/int
import gleam/io
import timing/clock
import topology/full
import topology/grid3d
import topology/imp3d
import topology/line
import types

fn build_topology(n: Int, t: types.Topology) -> List(List(Int)) {
  case t {
    types.Full -> full.build(n)
    types.Line -> line.build(n)
    types.Grid3D -> grid3d.build(n)
    types.Imp3D -> imp3d.build(n)
  }
}

pub fn run_with_failure(
  n: Int,
  t: types.Topology,
  a: types.Algorithm,
  f: types.Failure,
) -> Nil {
  let graph = build_topology(n, t)
  let start = clock.now_millis()

  // Start algorithm and get a waiter subject from a tiny shim
  let waiter = process.new_subject()
  let shim = fn() {
    case a {
      types.Gossip -> gossip.run(n, graph, f)
      types.PushSum -> push_sum.run(n, graph, f)
    }
    process.send(waiter, Nil)
  }
  let _pid = process.spawn_unlinked(shim)

  // Wait up to 120s for completion
  let done = process.receive(from: waiter, within: 120_000)
  let elapsed = clock.elapsed_ms(start)
  case done {
    Ok(_) -> io.println("Converged in " <> int.to_string(elapsed) <> " ms")
    Error(_) ->
      io.println("Timed out after " <> int.to_string(elapsed) <> " ms")
  }
}

pub fn run(n: Int, t: types.Topology, a: types.Algorithm) -> Nil {
  run_with_failure(n, t, a, types.NoFailure)
}
