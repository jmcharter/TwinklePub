import config.{type TwinklePubConfig}
import gleam/http.{Get, Post}
import gleam/option.{None, Some}
import gleam/string_tree
import utils
import web
import wisp.{type Request, type Response}

import micropub.{MicropubConfig, get_micropub_config_json}

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
  let query = wisp.get_query(req)
  let q_param = utils.get_last_query_param(query, "q")
  case q_param {
    Ok(param) ->
      case handle_q_param(req, config, param) {
        Some(response) -> response
        None -> wisp.not_found()
      }
    _ -> todo
  }
}

fn handle_q_param(_req: Request, config: TwinklePubConfig, param: String) {
  case param {
    "config" -> Some(handle_micropub_config(config))
    _ -> None
  }
}

fn handle_micropub_config(config: TwinklePubConfig) {
  let config =
    MicropubConfig(config.token_endpoint, case config.syndicate_to {
      Some(syndicate_to) -> syndicate_to
      None -> []
    })
    |> get_micropub_config_json()
    |> string_tree.from_string
  wisp.json_response(config, 200)
}
