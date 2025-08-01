import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

import twinkle_pub/auth.{type Scope}

pub type Location =
  String

pub type MicropubAction {
  Create
  Update
  Delete
  Undelete
}

pub fn post_type_to_scope(post_type: PostTypeData) -> Scope {
  case post_type {
    PostTypeData("h-entry") -> auth.ScopeCreate
    PostTypeData(_) -> auth.ScopeCreate
  }
}

pub type PostTypeData {
  PostTypeData(String)
}

pub type ContentData {
  ContentData(String)
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

pub type MicropubPost {
  MicropubPost(
    micropub_type: PostTypeData,
    // action: MicropubAction,
    content: Option(ContentData),
    access_token: Option(String),
  )
}

pub fn empty_post() -> MicropubPost {
  MicropubPost(PostTypeData("h-entry"), None, None)
}
