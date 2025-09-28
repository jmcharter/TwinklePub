import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/timestamp
import twinkle_pub/micropub/post

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

pub fn prop_list_to_singular(prop_list: Option(List(a))) -> Option(a) {
  case prop_list {
    None -> None
    Some(items) -> list.first(items) |> option.from_result
  }
}

pub fn generate_slug(post_body: post.PostBody(post.PostTyped)) {
  let props = post_body.properties
  let post_type = post_body.post_type |> option.unwrap(post.Note)
  let name = case post_type {
    post.Article -> props.name |> prop_list_to_singular
    _ -> {
      let now_string =
        timestamp.system_time() |> timestamp.to_unix_seconds |> float.to_string
      let post_type_string = post_type |> post.post_type_to_string
      todo
    }
  }
}
