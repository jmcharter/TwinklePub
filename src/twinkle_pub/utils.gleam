import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
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

/// Generate a URL-safe slug for a post.
/// For articles, uses the name/title. For other post types, generates a
/// timestamp-based slug with the post type prefix.
pub fn generate_slug(post_body: post.PostBody(post.PostTyped)) -> String {
  let props = post_body.properties
  let post_type = post_body.post_type |> option.unwrap(post.Note)

  case post_type {
    post.Article ->
      props.name
      |> prop_list_to_singular
      |> option.map(slugify)
      |> option.unwrap(generate_timestamp_slug("article"))
    _ -> generate_timestamp_slug(post.post_type_to_string(post_type))
  }
}

/// Generate a timestamp-based slug with a prefix
fn generate_timestamp_slug(prefix: String) -> String {
  let now = timestamp.system_time() |> timestamp.to_unix_seconds
  let seconds = float.truncate(now)
  prefix <> "-" <> int.to_string(seconds)
}

/// Convert text to a URL-safe slug
fn slugify(text: String) -> String {
  text
  |> string.lowercase
  |> string.replace(" ", "-")
  |> string.to_graphemes
  |> list.filter(fn(c) { is_slug_char(c) })
  |> string.concat
  |> string.slice(0, 80)
}

fn is_slug_char(c: String) -> Bool {
  case c {
    "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" -> True
    "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" -> True
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "-" -> True
    _ -> False
  }
}
