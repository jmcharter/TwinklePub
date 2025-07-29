import gleam/http.{Get, Post}
import gleam/string_tree

import wisp.{type Request, type Response}

import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/router/micropub.{micropub}
import twinkle_pub/web

pub fn handle_request(req: Request, config: TwinklePubConfig) -> Response {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["micropub"] -> micropub(req, config)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)
  let body = string_tree.from_string("Hello, Gleam!")
  wisp.ok() |> wisp.html_body(body)
}
