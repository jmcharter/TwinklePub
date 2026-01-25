import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import twinkle_pub/http_errors
import twinkle_pub/micropub/post.{type PostBody}

pub type FormValue =
  List(#(String, String))

pub fn form_data_to_micropub_post(
  form_data: FormValue,
) -> Result(PostBody(post.PostTyped), http_errors.MicropubError) {
  let action = case get_form_value(form_data, "action") {
    Some("update") -> post.Update
    Some("delete") -> post.Delete
    Some("undelete") -> post.Undelete
    _ -> post.Create
  }

  let object_type = case get_form_value(form_data, "h") {
    Some("entry") -> [post.HEntry]
    _ -> [post.HEntry]
  }

  let access_token = get_form_value(form_data, "access_token")
  let properties = build_properties_from_form(form_data)

  Ok(
    post.PostBody(
      ..post.new(),
      object_type:,
      action:,
      properties:,
      access_token:,
    )
    |> post.with_post_type,
  )
}

fn build_properties_from_form(form_data: FormValue) -> post.Properties {
  post.Properties(
    content: extract_content(form_data),
    name: extract_simple_values(form_data, "name"),
    summary: extract_simple_values(form_data, "summary"),
    published: extract_simple_values(form_data, "published"),
    updated: extract_simple_values(form_data, "updated"),
    category: extract_simple_values(form_data, "category"),
    in_reply_to: extract_simple_values(form_data, "in-reply-to"),
    rsvp: extract_simple_values(form_data, "rsvp"),
    like_of: extract_simple_values(form_data, "like-of"),
    video: extract_simple_values(form_data, "video"),
    photo: extract_simple_values(form_data, "photo"),
    repost_of: extract_simple_values(form_data, "repost-of"),
    read_of: extract_simple_values(form_data, "read-of"),
    watch_of: extract_simple_values(form_data, "watch-of"),
    syndication: extract_simple_values(form_data, "syndication"),
  )
}

fn extract_content(values: FormValue) -> Option(List(post.Content)) {
  case get_form_values(values, "content") {
    [] -> None
    content_values -> Some(list.map(content_values, post.SimpleContent))
  }
}

fn extract_simple_values(values: FormValue, key: String) -> Option(List(String)) {
  case get_form_values(values, key) {
    [] -> None
    items -> Some(items)
  }
}

fn get_form_value(values: FormValue, key: String) -> Option(String) {
  case list.key_find(values, key) {
    Error(_) -> None
    Ok(value) -> Some(value)
  }
}

fn get_form_values(values: FormValue, key: String) -> List(String) {
  values
  |> list.filter(fn(pair) {
    let normalized_key = string.replace(pair.0, "[]", "")
    normalized_key == key
  })
  |> list.map(fn(pair) { pair.1 })
}
