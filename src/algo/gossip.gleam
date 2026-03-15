import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/otp/actor
import types
import util/list_ext
import util/random

pub type GossipMsg {
  SetNeighborhood(neighbors: List(Int), all: List(process.Subject(GossipMsg)))
  Rumor
  Tick
  Stop
}

// Coordinator
pub type CoordMsg {
  Register(node_id: Int, subject: process.Subject(GossipMsg))
  Terminated(node_id: Int)
  WaitForAll(reply: process.Subject(Nil))
}

pub fn run(
  num_nodes: Int,
  graph: List(List(Int)),
  failure: types.Failure,
) -> Nil {
  let assert Ok(coord) =
    actor.new(coord_state(num_nodes, failure))
    |> actor.on_message(handle_coord)
    |> actor.start

  let coord_subject = coord.data
  let nodes = start_nodes_loop(num_nodes, 0, [], coord_subject, failure)
  register_nodes_with_coord_loop(nodes, 0, coord_subject)
  send_neighborhoods_loop(graph, nodes, 0)

  case list_ext.get_at(nodes, 0) {
    Ok(s) -> process.send(s, Rumor)
    Error(_) -> Nil
  }

  let reply = process.new_subject()
  process.send(coord_subject, WaitForAll(reply))
  let _ = process.receive(from: reply, within: 600_000)
  Nil
}

fn start_nodes_loop(
  total: Int,
  i: Int,
  acc: List(process.Subject(GossipMsg)),
  coord: process.Subject(CoordMsg),
  failure: types.Failure,
) -> List(process.Subject(GossipMsg)) {
  case i < total {
    True -> {
      let init = fn(subject) {
        let state =
          node_state(
            id: i,
            neighbors: [],
            all: [],
            heard: 0,
            rng: random.from_seed(12_345 + i),
            coord: coord,
            failure: failure,
            alive: True,
            self_subject: subject,
            announced: False,
          )
        actor.initialised(state)
        |> actor.returning(subject)
        |> Ok
      }
      let assert Ok(started) =
        actor.new_with_initialiser(1000, init)
        |> actor.on_message(handle_node)
        |> actor.start
      start_nodes_loop(total, i + 1, [started.data, ..acc], coord, failure)
    }
    False -> list.reverse(acc)
  }
}

fn register_nodes_with_coord_loop(
  nodes: List(process.Subject(GossipMsg)),
  i: Int,
  coord: process.Subject(CoordMsg),
) -> Nil {
  case nodes {
    [] -> Nil
    [s, ..rest] -> {
      process.send(coord, Register(i, s))
      register_nodes_with_coord_loop(rest, i + 1, coord)
    }
  }
}

fn send_neighborhoods_loop(
  graph: List(List(Int)),
  nodes: List(process.Subject(GossipMsg)),
  i: Int,
) -> Nil {
  case graph {
    [] -> Nil
    [neighs, ..rest] -> {
      case list_ext.get_at(nodes, i) {
        Ok(s) -> process.send(s, SetNeighborhood(neighs, nodes))
        Error(_) -> Nil
      }
      send_neighborhoods_loop(rest, nodes, i + 1)
    }
  }
}

// Coordinator state and handler

pub type CoordState {
  CoordState(
    total: Int,
    terminated: Int,
    nodes: List(process.Subject(GossipMsg)),
    waiter: option.Option(process.Subject(Nil)),
    failure: types.Failure,
  )
}

fn coord_state(total: Int, failure: types.Failure) -> CoordState {
  CoordState(
    total:,
    terminated: 0,
    nodes: [],
    waiter: option.None,
    failure: failure,
  )
}

fn handle_coord(
  state: CoordState,
  msg: CoordMsg,
) -> actor.Next(CoordState, CoordMsg) {
  case msg {
    Register(_id, subject) -> {
      actor.continue(CoordState(..state, nodes: [subject, ..state.nodes]))
    }
    Terminated(_id) -> {
      let new_term = state.terminated + 1
      let new_state = CoordState(..state, terminated: new_term)
      case new_term >= state.total, state.waiter {
        True, option.Some(reply) -> {
          list.each(new_state.nodes, fn(subject) { process.send(subject, Stop) })
          process.send(reply, Nil)
          actor.stop()
        }
        _, _ -> actor.continue(new_state)
      }
    }
    WaitForAll(reply) -> {
      case state.terminated >= state.total {
        True -> {
          process.send(reply, Nil)
          actor.stop()
        }
        False -> actor.continue(CoordState(..state, waiter: option.Some(reply)))
      }
    }
  }
}

// Node state and handler

pub type NodeState {
  NodeState(
    id: Int,
    neighbors: List(Int),
    all: List(process.Subject(GossipMsg)),
    heard: Int,
    rng: random.Rng,
    coord: process.Subject(CoordMsg),
    failure: types.Failure,
    alive: Bool,
    self_subject: process.Subject(GossipMsg),
    announced: Bool,
  )
}

fn node_state(
  id id_: Int,
  neighbors neighbors_: List(Int),
  all all_: List(process.Subject(GossipMsg)),
  heard heard_: Int,
  rng rng_: random.Rng,
  coord coord_: process.Subject(CoordMsg),
  failure failure_: types.Failure,
  alive alive_: Bool,
  self_subject self_subject_: process.Subject(GossipMsg),
  announced announced_: Bool,
) -> NodeState {
  NodeState(
    id: id_,
    neighbors: neighbors_,
    all: all_,
    heard: heard_,
    rng: rng_,
    coord: coord_,
    failure: failure_,
    alive: alive_,
    self_subject: self_subject_,
    announced: announced_,
  )
}

fn should_drop_or_die(state: NodeState) -> #(Bool, NodeState) {
  case state.failure {
    types.NoFailure -> #(False, state)
    types.NodeDeath(rate) -> {
      let #(p, rng2) = random.next_float(state.rng)
      case p <=. rate {
        True -> #(True, NodeState(..state, rng: rng2, alive: False))
        False -> #(False, NodeState(..state, rng: rng2))
      }
    }
    types.LinkTemporary(rate) -> {
      let #(p, rng2) = random.next_float(state.rng)
      #(p <=. rate, NodeState(..state, rng: rng2))
    }
    types.LinkPermanent(rate) -> {
      let #(p, rng2) = random.next_float(state.rng)
      case p <=. rate {
        True -> #(True, NodeState(..state, rng: rng2, neighbors: []))
        False -> #(False, NodeState(..state, rng: rng2))
      }
    }
  }
}

fn pick_neighbor(
  state: NodeState,
) -> #(option.Option(process.Subject(GossipMsg)), NodeState) {
  case state.neighbors {
    [] -> #(option.None, state)
    _ -> {
      let count = list.length(state.neighbors)
      let #(idx_in_neighs, rng2) = random.next_int(state.rng, count)
      case list_ext.get_at(state.neighbors, idx_in_neighs) {
        Ok(neighbor_id) ->
          case list_ext.get_at(state.all, neighbor_id) {
            Ok(subj) -> #(option.Some(subj), NodeState(..state, rng: rng2))
            Error(_) -> #(option.None, NodeState(..state, rng: rng2))
          }
        Error(_) -> #(option.None, NodeState(..state, rng: rng2))
      }
    }
  }
}

fn handle_node(
  state: NodeState,
  msg: GossipMsg,
) -> actor.Next(NodeState, GossipMsg) {
  case msg {
    SetNeighborhood(neighs, all) ->
      actor.continue(NodeState(..state, neighbors: neighs, all: all))
    Rumor -> {
      case state.alive {
        False -> actor.stop()
        True -> {
          let #(drop_or_die, state2) = should_drop_or_die(state)
          case drop_or_die {
            True -> actor.continue(state2)
            False -> {
              let new_heard = state2.heard + 1
              // Start self-ticking on first rumor received
              case new_heard == 1 {
                True -> process.send(state2.self_subject, Tick)
                False -> Nil
              }
              let state3 = NodeState(..state2, heard: new_heard)
              let final_state = case new_heard >= 10 && !state3.announced {
                True -> {
                  process.send(state3.coord, Terminated(state3.id))
                  NodeState(..state3, announced: True)
                }
                False -> state3
              }
              actor.continue(final_state)
            }
          }
        }
      }
    }
    Tick -> {
      case state.alive {
        False -> actor.stop()
        True -> {
          let #(maybe_target, next_state) = pick_neighbor(state)
          case maybe_target {
            option.Some(target) -> {
              process.send(target, Rumor)
              process.send(next_state.self_subject, Tick)
              actor.continue(next_state)
            }
            option.None -> {
              case !next_state.announced {
                True ->
                  process.send(next_state.coord, Terminated(next_state.id))
                False -> Nil
              }
              actor.stop()
            }
          }
        }
      }
    }
    Stop -> actor.stop()
  }
}
