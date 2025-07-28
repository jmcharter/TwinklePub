import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string_tree
import utils
import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["micropub"] -> micropub(req)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) {
  use <- wisp.require_method(req, Get)
  let body = string_tree.from_string("Hello, Gleam!")
  wisp.ok() |> wisp.html_body(body)
}

fn micropub(req: Request) {
  let query = wisp.get_query(req)
  let q_param = utils.get_last_query_param(query, "q")
  case q_param {
    Ok(param) ->
      case handle_q_param(req, param) {
        Some(response) -> response
        None -> wisp.not_found()
      }
    _ -> todo
  }
}

fn handle_q_param(req: Request, param: String) {
  case param {
    "config" -> Some(handle_micropub_config(req))
    _ -> None
  }
}

fn handle_micropub_config(req: Request) {
  let config =
    get_micropub_config()
    |> string_tree.from_string
  wisp.json_response(config, 200)
}

pub type MicropubConfig {
  MicropubConfig(media_endpoint: String, syndicate_to: List(SyndicateTarget))
}

pub type SyndicateTarget {
  SyndicateTarget(uid: String, name: String, service: Service, user: User)
}

pub type Service {
  Service(name: String, url: String, photo: String)
}

pub type User {
  User(name: String, url: String, photo: String)
}

fn get_micropub_config() {
  let user = User("john smith", "http://localhost/user", "")
  let service =
    Service(
      "foo",
      "http://localhost/service",
      "http://localhost/service/photo.jpg",
    )
  let syndicate_target =
    SyndicateTarget("0001-001-01-01", "foobar", service, user)

  let config_json =
    MicropubConfig("http://localhost/media", [syndicate_target])
    |> encode_micropub_config_to_json
  config_json
}

fn encode_micropub_config_to_json(config: MicropubConfig) -> String {
  json.object([
    #("media-endpoint", json.string(config.media_endpoint)),
    #(
      "syndicate-to",
      json.array(config.syndicate_to, encode_syndicate_target_to_json_object),
    ),
  ])
  |> json.to_string()
}

fn encode_syndicate_target_to_json_object(target: SyndicateTarget) -> json.Json {
  json.object([
    #("uid", json.string(target.uid)),
    #("name", json.string(target.name)),
    #("service", encode_service_to_json_object(target.service)),
    #("user", encode_user_to_json_object(target.user)),
  ])
}

fn encode_service_to_json_object(service: Service) -> json.Json {
  json.object([
    #("name", json.string(service.name)),
    #("url", json.string(service.url)),
    #("photo", json.string(service.photo)),
  ])
}

fn encode_user_to_json_object(user: User) -> json.Json {
  json.object([
    #("name", json.string(user.name)),
    #("url", json.string(user.url)),
    #("photo", json.string(user.photo)),
  ])
}
