import gleam/http.{Get, Post}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string_tree
import wisp.{type Request, type Response}

import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/http_errors.{InvalidRequest, error_to_response}
import twinkle_pub/micropub.{MicropubConfig, get_micropub_config_json}
import twinkle_pub/utils
import twinkle_pub/web

pub fn handle_request(req: Request, config: TwinklePubConfig) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["micropub"] -> micropub(req, config)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) {
  use <- wisp.require_method(req, Get)
  let body = string_tree.from_string("Hello, Gleam!")
  wisp.ok() |> wisp.html_body(body)
}

fn micropub(req: Request, config: TwinklePubConfig) {
  case req.method {
    Get -> micropub_get(req, config)
    Post -> todo
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn micropub_get(req: Request, config: TwinklePubConfig) -> Response {
  let query = wisp.get_query(req)
  let q_param = case query {
    [] -> Error("Missing required parameter 'q'")
    _ ->
      utils.get_last_query_param(query, "q")
      |> result.map_error(fn(_) { "Missing required parameter 'q'" })
  }

  case q_param {
    Ok(param) ->
      case handle_q_param(req, config, param) {
        Some(response) -> response
        None ->
          InvalidRequest("Unsupported query parameter value")
          |> error_to_response
      }
    Error(msg) -> InvalidRequest(msg) |> error_to_response
  }
}

fn handle_q_param(
  _req: Request,
  config: TwinklePubConfig,
  param: String,
) -> Option(Response) {
  case param {
    "config" -> Some(handle_micropub_config(config))
    _ -> None
  }
}

fn handle_micropub_config(config: TwinklePubConfig) -> Response {
  let config =
    MicropubConfig(config.token_endpoint, case config.syndicate_to {
      Some(syndicate_to) -> syndicate_to
      None -> []
    })
    |> get_micropub_config_json()
    |> string_tree.from_string
  wisp.json_response(config, 200)
}
