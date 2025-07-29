import gleam/dynamic/decode
import gleam/function
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type MicropubConfig {
  MicropubConfig(
    media_endpoint: Option(String),
    syndicate_to: List(SyndicateTarget),
  )
}

pub type SyndicateTarget {
  SyndicateTarget(
    uid: String,
    name: String,
    service: Option(Service),
    user: Option(User),
  )
}

pub type Service {
  Service(name: String, url: Option(String), photo: Option(String))
}

pub type User {
  User(name: String, url: Option(String), photo: Option(String))
}

pub fn get_micropub_config_json(config: MicropubConfig) -> String {
  config
  |> encode_micropub_config_to_json
}

fn encode_micropub_config_to_json(config: MicropubConfig) -> String {
  let optional_fields =
    [
      case config.media_endpoint {
        Some(endpoint) -> Ok(#("media-endpoint", json.string(endpoint)))
        None -> Error(Nil)
      },
    ]
    |> list.filter_map(function.identity)
  [
    #(
      "syndicate-to",
      json.array(config.syndicate_to, encode_syndicate_target_to_json_object),
    ),
    ..optional_fields
  ]
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  |> json.object
  |> json.to_string()
}

fn encode_syndicate_target_to_json_object(target: SyndicateTarget) -> json.Json {
  let optional_fields =
    [
      case target.service {
        Some(service) ->
          Ok(#("service", encode_service_to_json_object(service)))
        None -> Error(Nil)
      },
      case target.user {
        Some(user) -> Ok(#("user", encode_user_to_json_object(user)))
        None -> Error(Nil)
      },
    ]
    |> list.filter_map(function.identity)

  [
    #("uid", json.string(target.uid)),
    #("name", json.string(target.name)),
    ..optional_fields
  ]
  |> json.object
}

fn encode_service_to_json_object(service: Service) -> json.Json {
  let optional_fields =
    [
      case service.url {
        Some(url) -> Ok(#("url", json.string(url)))
        None -> Error(Nil)
      },
      case service.photo {
        Some(photo) -> Ok(#("photo", json.string(photo)))
        None -> Error(Nil)
      },
    ]
    |> list.filter_map(function.identity)
  [#("name", json.string(service.name)), ..optional_fields]
  |> json.object
}

fn encode_user_to_json_object(user: User) -> json.Json {
  let optional_fields =
    [
      case user.url {
        Some(url) -> Ok(#("url", json.string(url)))
        None -> Error(Nil)
      },
      case user.photo {
        Some(photo) -> Ok(#("photo", json.string(photo)))
        None -> Error(Nil)
      },
    ]
    |> list.filter_map(function.identity)
  [#("name", json.string(user.name)), ..optional_fields]
  |> json.object
}

pub fn syndicate_target_decoder() -> decode.Decoder(SyndicateTarget) {
  use uid <- decode.field("uid", decode.string)
  use name <- decode.field("name", decode.string)
  use service <- decode.optional_field(
    "service",
    None,
    decode.optional(service_decoder()),
  )
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
  decode.success(SyndicateTarget(uid:, name:, service:, user:))
}

fn service_decoder() -> decode.Decoder(Service) {
  use name <- decode.field("name", decode.string)
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use photo <- decode.optional_field(
    "photo",
    None,
    decode.optional(decode.string),
  )
  decode.success(Service(name:, url:, photo:))
}

fn user_decoder() -> decode.Decoder(User) {
  use name <- decode.field("name", decode.string)
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use photo <- decode.optional_field(
    "photo",
    None,
    decode.optional(decode.string),
  )
  decode.success(User(name:, url:, photo:))
}
