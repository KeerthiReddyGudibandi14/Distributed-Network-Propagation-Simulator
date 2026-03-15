fn get_at_loop(list: List(a), index: Int) -> Result(a, Nil) {
  case list, index {
    [], _ -> Error(Nil)
    [x, .._], 0 -> Ok(x)
    [_, ..rest], _ -> get_at_loop(rest, index - 1)
  }
}

pub fn get_at(list: List(a), index: Int) -> Result(a, Nil) {
  case index < 0 {
    True -> Error(Nil)
    False -> get_at_loop(list, index)
  }
}
