import gleam/dynamic/decode
import gleam/option.{None, Some}

import twinkle_pub/micropub/post

pub fn post_body_decoder() -> decode.Decoder(post.PostBody) {
  // use object_type <- decode.optional_field(
  //   "type",
  //   [post.HEntry],
  //   post_type_decoder(),
  // )
  use object_type <- decode.then(post_type_decoder())
  use action <- decode.optional_field(
    "action",
    post.Create,
    post_action_decoder(),
  )
  use properties <- decode.optional_field(
    "properties",
    post.empty_properties(),
    post_properties_decoder(),
  )
  use access_token <- decode.optional_field(
    "access_token",
    None,
    decode.optional(decode.string),
  )
  decode.success(post.PostBody(
    object_type:,
    action:,
    properties:,
    access_token:,
  ))
}

/// This is quite redundant as we're always going to return HEntry, but in the
/// future we may handle more types
fn post_type_decoder() -> decode.Decoder(List(post.ObjectType)) {
  decode.optional_field(
    "type",
    ["h-entry"],
    decode.list(decode.string),
    fn(type_list) {
      case type_list {
        [_first, ..] -> decode.success([post.HEntry])
        [] -> decode.success([post.HEntry])
      }
    },
  )
}

fn post_action_decoder() -> decode.Decoder(post.MicropubAction) {
  decode.optional_field("action", "create", decode.string, fn(action) {
    decode.success(case action {
      "update" -> post.Update
      "delete" -> post.Delete
      "undelete" -> post.Undelete
      _ -> post.Create
    })
  })
}

fn post_properties_decoder() -> decode.Decoder(post.Properties) {
  use content <- decode.optional_field(
    "content",
    None,
    post_property_values_decoder(post_content_decoder()),
  )
  use name <- decode.optional_field(
    "name",
    None,
    post_property_values_decoder(decode.string),
  )

  use summary <- decode.optional_field(
    "summary",
    None,
    post_property_values_decoder(decode.string),
  )
  use published <- decode.optional_field(
    "published",
    None,
    post_property_values_decoder(decode.string),
  )
  use updated <- decode.optional_field(
    "updated",
    None,
    post_property_values_decoder(decode.string),
  )
  use category <- decode.optional_field(
    "category",
    None,
    post_property_values_decoder(decode.string),
  )
  use in_reply_to <- decode.optional_field(
    "in_reply_to",
    None,
    post_property_values_decoder(decode.string),
  )
  use repost_of <- decode.optional_field(
    "repost_of",
    None,
    post_property_values_decoder(decode.string),
  )
  use syndication <- decode.optional_field(
    "syndication",
    None,
    post_property_values_decoder(decode.string),
  )
  decode.success(post.Properties(
    content:,
    name:,
    summary:,
    published:,
    updated:,
    category:,
    in_reply_to:,
    repost_of:,
    syndication:,
  ))
}

fn post_property_values_decoder(
  item_decoder: decode.Decoder(a),
) -> decode.Decoder(post.PropertyValues(a)) {
  decode.list(item_decoder) |> decode.map(Some)
}

fn post_content_decoder() -> decode.Decoder(post.Content) {
  decode.string |> decode.map(post.SimpleContent)
}
