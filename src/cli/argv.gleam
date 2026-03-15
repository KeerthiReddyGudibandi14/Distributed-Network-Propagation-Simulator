import gleam/list
import gleam/erlang/charlist.{type Charlist}

@external(erlang, "init", "get_plain_arguments")
fn raw_arguments() -> List(Charlist)

pub fn arguments() -> List(String) {
  list.map(raw_arguments(), charlist.to_string)
}

