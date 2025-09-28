import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/timestamp.{type Timestamp}

import twinkle_pub/auth.{type Scope}

pub type Location =
  String

pub type Url =
  String

pub type ObjectType {
  HEntry
}

pub type PostType {
  Article
  Like
  Note
  Photo
  Read
  Reply
  Repost
  RSVP
  Summary
  Video
  Watch
}

pub fn post_type_to_string(post_type: PostType) {
  case post_type {
    Article -> "article"
    Like -> "like"
    Note -> "note"
    Photo -> "photo"
    RSVP -> "rsvp"
    Read -> "read"
    Reply -> "reply"
    Repost -> "repost"
    Summary -> "summary"
    Video -> "video"
    Watch -> "watch"
  }
}

pub type Content {
  SimpleContent(String)
  RichContent(html: Option(String), value: Option(String))
}

pub type PropertyValues(a) =
  Option(List(a))

pub type Properties {
  Properties(
    content: PropertyValues(Content),
    name: PropertyValues(String),
    summary: PropertyValues(String),
    published: PropertyValues(String),
    updated: PropertyValues(String),
    category: PropertyValues(String),
    in_reply_to: PropertyValues(Url),
    rsvp: PropertyValues(String),
    like_of: PropertyValues(String),
    video: PropertyValues(String),
    photo: PropertyValues(String),
    repost_of: PropertyValues(Url),
    read_of: PropertyValues(String),
    watch_of: PropertyValues(String),
    syndication: PropertyValues(Url),
  )
}

pub fn empty_properties() -> Properties {
  Properties(
    content: None,
    name: None,
    summary: None,
    published: None,
    updated: None,
    category: None,
    in_reply_to: None,
    rsvp: None,
    like_of: None,
    video: None,
    photo: None,
    repost_of: None,
    read_of: None,
    watch_of: None,
    syndication: None,
  )
}

pub type HCite {
  HCite(
    name: PropertyValues(String),
    published: PropertyValues(Timestamp),
    author: PropertyValues(String),
    url: PropertyValues(Url),
    uid: PropertyValues(String),
    publication: PropertyValues(String),
    accessed: PropertyValues(Timestamp),
    photo: PropertyValues(Url),
  )
}

pub type MicropubAction {
  Create
  Update
  Delete
  Undelete
}

pub fn action_to_scope(object_type: MicropubAction) -> Scope {
  case object_type {
    Create -> auth.ScopeCreate
    Update -> auth.ScopeUpdate
    Delete -> auth.ScopeDelete
    Undelete -> auth.ScopeCreate
  }
}

pub fn get_field(
  data: Dict(String, String),
  key: String,
  constructor: fn(String) -> data_type,
) -> Option(data_type) {
  case dict.get(data, key) {
    // Handle type: h-entry, etc
    Ok(value) if key == "h" -> Some(constructor("h-" <> value))
    Ok(value) -> Some(constructor(value))
    Error(_) -> None
  }
}

pub type PostUntyped

pub type PostTyped

pub type PostBody(a) {
  PostBody(
    object_type: List(ObjectType),
    post_type: Option(PostType),
    action: MicropubAction,
    properties: Properties,
    access_token: Option(String),
  )
}

pub fn new() -> PostBody(PostUntyped) {
  PostBody(
    object_type: [HEntry],
    post_type: None,
    action: Create,
    properties: empty_properties(),
    access_token: None,
  )
}

/// Determine the post type of a typeless PostBody and return a new typed PostBody
/// Defaults to Note type if a more specific type isn't determined.
/// See https://indieweb.org/post-type-discovery for the discovery algorithm
pub fn with_post_type(post_body: PostBody(PostUntyped)) -> PostBody(PostTyped) {
  let props = post_body.properties
  let post_type =
    props
    |> check_rsvp
    |> result.lazy_or(fn() { check_property(props.in_reply_to, Reply) })
    |> result.lazy_or(fn() { check_property(props.repost_of, Repost) })
    |> result.lazy_or(fn() { check_property(props.like_of, Like) })
    |> result.lazy_or(fn() { check_property(props.read_of, Read) })
    |> result.lazy_or(fn() { check_property(props.watch_of, Watch) })
    |> result.lazy_or(fn() { check_property(props.video, Video) })
    |> result.lazy_or(fn() { check_property(props.photo, Photo) })
    |> result.lazy_or(fn() { check_property(props.summary, Summary) })
    |> result.unwrap(Some(Note))
  PostBody(..post_body, post_type:)
}

fn check_rsvp(props: Properties) -> Result(Option(PostType), Nil) {
  let valid_values = ["yes", "no", "maybe", "interested"]
  case props.rsvp {
    None -> Error(Nil)
    Some(rsvp) ->
      case rsvp {
        [first, ..] ->
          case list.contains(valid_values, first) {
            True -> Ok(Some(RSVP))
            False -> Error(Nil)
          }
        [] -> Error(Nil)
      }
  }
}

fn check_property(
  prop: PropertyValues(a),
  post_type: PostType,
) -> Result(Option(PostType), Nil) {
  case prop {
    None -> Error(Nil)
    Some(_) -> Ok(Some(post_type))
  }
}
