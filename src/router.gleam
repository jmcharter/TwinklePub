import config.{type TwinklePubConfig}
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string_tree
import utils
import web
import wisp.{type Request, type Response}

import micropub.{get_micropub_config}

pub fn handle_request(req: Request, config: TwinklePubConfig) -> Response {
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

fn handle_q_param(_req: Request, param: String) {
  case param {
    "config" -> Some(handle_micropub_config())
    _ -> None
  }
}

fn handle_micropub_config() {
  let config =
    get_micropub_config()
    |> string_tree.from_string
  wisp.json_response(config, 200)
}
