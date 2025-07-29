import gleam/http.{Get, Post}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string_tree

import wisp.{type Request, type Response}

import twinkle_pub/auth
import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/http_errors.{InvalidRequest, error_to_response}
import twinkle_pub/micropub.{MicropubConfig, get_micropub_config_json}
import twinkle_pub/utils

pub fn micropub(req: Request, config: TwinklePubConfig) {
  case req.method {
    Get -> micropub_get(req, config)
    Post -> micropub_post(req, config)
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

fn micropub_post(req: Request, config: TwinklePubConfig) {
  case auth.verify_access_token(req, config) {
    Error(err) -> error_to_response(err)
    Ok(auth_response) -> {
      todo
    }
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
    MicropubConfig(config.media_endpoint, case config.syndicate_to {
      Some(syndicate_to) -> syndicate_to
      None -> []
    })
    |> get_micropub_config_json()
    |> string_tree.from_string
  wisp.json_response(config, 200)
}
