import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/actor
import types
import util/list_ext
import util/random

pub type PSMsg {
  SetNeighborhood(neighbors: List(Int), all: List(process.Subject(PSMsg)))
  Transfer(s: Float, w: Float)
  Tick
  Stop
}

pub type CoordMsg {
  Register(node_id: Int, subject: process.Subject(PSMsg))
  Terminated(node_id: Int)
  WaitForAll(reply: process.Subject(Nil))
}

fn map_ids_to_subjects(
  all: List(process.Subject(PSMsg)),
  ids: List(Int),
) -> List(process.Subject(PSMsg)) {
  case ids {
    [] -> []
    [i, ..rest] -> {
      let tail = map_ids_to_subjects(all, rest)
      case list_ext.get_at(all, i) {
        Ok(s) -> [s, ..tail]
        Error(_) -> tail
      }
    }
  }
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

  // Start ticking all nodes to propagate
  start_ticks(nodes)

  let reply = process.new_subject()
  process.send(coord_subject, WaitForAll(reply))
  let _ = process.receive(from: reply, within: 600_000)
  Nil
}

fn start_ticks(nodes: List(process.Subject(PSMsg))) {
  case nodes {
    [] -> Nil
    [s, ..rest] -> {
      process.send(s, Tick)
      start_ticks(rest)
    }
  }
}

fn start_nodes_loop(
  total: Int,
  i: Int,
  acc: List(process.Subject(PSMsg)),
  coord: process.Subject(CoordMsg),
  failure: types.Failure,
) -> List(process.Subject(PSMsg)) {
  case i < total {
    True -> {
      let init = fn(subject) {
        let state =
          node_state(
            id: i,
            neighbors: [],
            s: int.to_float(i),
            w: 1.0,
            ratio: 0.0,
            stable: 0,
            rng: random.from_seed(9999 + i),
            coord: coord,
            failure: failure,
            alive: True,
            self_subject: subject,
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
  nodes: List(process.Subject(PSMsg)),
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
  nodes: List(process.Subject(PSMsg)),
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

pub type CoordState {
  CoordState(
    total: Int,
    terminated: Int,
    waiter: option.Option(process.Subject(Nil)),
    failure: types.Failure,
  )
}

fn coord_state(total: Int, failure: types.Failure) -> CoordState {
  CoordState(total:, terminated: 0, waiter: option.None, failure: failure)
}

fn handle_coord(
  state: CoordState,
  msg: CoordMsg,
) -> actor.Next(CoordState, CoordMsg) {
  case msg {
    Register(_, _) -> actor.continue(state)
    Terminated(_) -> {
      let new_term = state.terminated + 1
      let new_state = CoordState(..state, terminated: new_term)
      case new_term >= state.total, state.waiter {
        True, option.Some(reply) -> {
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

pub type NodeState {
  NodeState(
    id: Int,
    neighbors: List(process.Subject(PSMsg)),
    s: Float,
    w: Float,
    ratio: Float,
    stable: Int,
    rng: random.Rng,
    coord: process.Subject(CoordMsg),
    failure: types.Failure,
    alive: Bool,
    self_subject: process.Subject(PSMsg),
  )
}

fn node_state(
  id id_: Int,
  neighbors neighbors_: List(process.Subject(PSMsg)),
  s s_: Float,
  w w_: Float,
  ratio ratio_: Float,
  stable stable_: Int,
  rng rng_: random.Rng,
  coord coord_: process.Subject(CoordMsg),
  failure failure_: types.Failure,
  alive alive_: Bool,
  self_subject self_subject_: process.Subject(PSMsg),
) -> NodeState {
  NodeState(
    id: id_,
    neighbors: neighbors_,
    s: s_,
    w: w_,
    ratio: ratio_,
    stable: stable_,
    rng: rng_,
    coord: coord_,
    failure: failure_,
    alive: alive_,
    self_subject: self_subject_,
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
) -> #(option.Option(process.Subject(PSMsg)), NodeState) {
  case state.neighbors {
    [] -> #(option.None, state)
    _ -> {
      let count = list.length(state.neighbors)
      let #(idx_in_neighs, rng2) = random.next_int(state.rng, count)
      case list_ext.get_at(state.neighbors, idx_in_neighs) {
        Ok(subj) -> #(option.Some(subj), NodeState(..state, rng: rng2))
        Error(_) -> #(option.None, NodeState(..state, rng: rng2))
      }
    }
  }
}

fn handle_node(state: NodeState, msg: PSMsg) -> actor.Next(NodeState, PSMsg) {
  case msg {
    SetNeighborhood(neighs, all) ->
      actor.continue(
        NodeState(..state, neighbors: map_ids_to_subjects(all, neighs)),
      )
    Tick -> {
      case state.alive {
        False -> actor.stop()
        True -> {
          let #(drop_or_die, state2) = should_drop_or_die(state)
          // If node has died, notify and stop
          case state2.alive == False {
            True -> {
              process.send(state2.coord, Terminated(state2.id))
              actor.stop()
            }
            False ->
              case drop_or_die {
                // Drop: reschedule tick to keep trying
                True -> {
                  process.send(state2.self_subject, Tick)
                  actor.continue(state2)
                }
                False -> {
                  let s1 = state2.s
                  let w1 = state2.w
                  let ratio1 = s1 /. w1
                  let delta = float.absolute_value(state2.ratio -. ratio1)
                  let stable1 = case delta <=. 1.0e-10 {
                    True -> state2.stable + 1
                    False -> 0
                  }
                  case stable1 >= 3 {
                    True -> {
                      process.send(state2.coord, Terminated(state2.id))
                      actor.stop()
                    }
                    False -> {
                      let s2 = s1 /. 2.0
                      let w2 = w1 /. 2.0
                      let #(maybe_target, next_state) =
                        pick_neighbor(
                          NodeState(
                            ..state2,
                            s: s2,
                            w: w2,
                            ratio: ratio1,
                            stable: stable1,
                          ),
                        )
                      case maybe_target {
                        option.Some(target) -> {
                          process.send(target, Transfer(s2, w2))
                          process.send(next_state.self_subject, Tick)
                          actor.continue(next_state)
                        }
                        option.None -> {
                          process.send(
                            next_state.coord,
                            Terminated(next_state.id),
                          )
                          actor.stop()
                        }
                      }
                    }
                  }
                }
              }
          }
        }
      }
    }
    Transfer(ds, dw) -> {
      let new_state = NodeState(..state, s: state.s +. ds, w: state.w +. dw)
      process.send(new_state.self_subject, Tick)
      actor.continue(new_state)
    }
    Stop -> actor.stop()
  }
}
