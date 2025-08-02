import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

import twinkle_pub/auth.{type Scope}

pub type Location =
  String

pub type Url =
  String

pub type ObjectType {
  HEntry
}

pub type Content {
  SimpleContent(String)
  RichContent(html: String, value: String)
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
    repost_of: PropertyValues(Url),
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
    repost_of: None,
    syndication: None,
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

pub type PostBody {
  PostBody(
    object_type: List(ObjectType),
    action: MicropubAction,
    properties: Properties,
    access_token: Option(String),
  )
}

pub fn new() -> PostBody {
  PostBody(
    object_type: [HEntry],
    action: Create,
    properties: empty_properties(),
    access_token: None,
  )
}
