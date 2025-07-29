import gleam/list
import gleam/result

/// Searches for parameters matching the given key and returns the value 
/// of the last match. Returns Error(Nil) if the key is not found.
pub fn get_last_query_param(
  params: List(#(String, String)),
  key: String,
) -> Result(String, Nil) {
  params
  |> list.filter(fn(param) {
    case param {
      #(k, _) if k == key -> True
      _ -> False
    }
  })
  |> list.last()
  |> result.map(fn(param) {
    case param {
      #(_, value) -> value
    }
  })
}
