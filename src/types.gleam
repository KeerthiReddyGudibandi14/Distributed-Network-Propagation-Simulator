import gleam/string
import gleam/float

pub type Topology {
  Full
  Grid3D
  Line
  Imp3D
}

pub fn parse_topology(input: String) -> Result(Topology, String) {
  let lowered = string.lowercase(input)
  case lowered {
    "full" -> Ok(Full)
    "3d" -> Ok(Grid3D)
    "grid3d" -> Ok(Grid3D)
    "line" -> Ok(Line)
    "imp3d" -> Ok(Imp3D)
    other -> Error("Unknown topology: " <> other)
  }
}

pub type Algorithm {
  Gossip
  PushSum
}

pub fn parse_algorithm(input: String) -> Result(Algorithm, String) {
  let lowered = string.lowercase(input)
  case lowered {
    "gossip" -> Ok(Gossip)
    "push-sum" -> Ok(PushSum)
    "push_sum" -> Ok(PushSum)
    "pushsum" -> Ok(PushSum)
    other -> Error("Unknown algorithm: " <> other)
  }
}

pub type Failure {
  NoFailure
  NodeDeath(rate: Float)
  LinkTemporary(rate: Float)
  LinkPermanent(rate: Float)
}

pub fn parse_failure(model: String, rate_s: String) -> Result(Failure, String) {
  let m = string.lowercase(model)
  let r = float.parse(rate_s)
  case m, r {
    "none", _ -> Ok(NoFailure)
    "node", Ok(rate) -> Ok(NodeDeath(rate))
    "link-temp", Ok(rate) -> Ok(LinkTemporary(rate))
    "link-perm", Ok(rate) -> Ok(LinkPermanent(rate))
    _, Error(_) -> Error("Invalid failure rate: " <> rate_s)
    other, _ -> Error("Unknown failure model: " <> other)
  }
}
