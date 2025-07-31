import gleam/dict
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/string_tree

import wisp.{type Request, type Response}

import twinkle_pub/auth.{type AuthResponse}
import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/http_errors.{
  InsufficientScope, InvalidRequest, ServerError, error_to_response,
}
import twinkle_pub/micropub.{MicropubConfig, get_micropub_config_json}
import twinkle_pub/micropub/post.{type MicropubPost, MicropubPost}
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
  case request.get_header(req, "content-type") {
    Error(_) ->
      InvalidRequest("Missing or unsupported 'content-type' in request header")
      |> error_to_response
    Ok(content_type) -> {
      case content_type {
        "application/json" -> todo
        "application/x-www-form-urlencoded" | "multipart/form-data" ->
          handle_micropub_form(req, config)
        _ ->
          InvalidRequest("Content type " <> content_type <> " not supported.")
          |> error_to_response
      }
    }
  }
}

fn handle_micropub_form(req: Request, config: TwinklePubConfig) {
  use form <- wisp.require_form(req)
  let wisp.FormData(values, _files) = form

  let post = form_data_to_micropub_post(values)
  echo post
  // post |> string.inspect |> wisp.log_info
  case auth.verify_access_token(req, post.access_token, config) {
    Error(err) -> err |> error_to_response
    Ok(auth_response) -> {
      let required_scope = case post.micropub_type {
        None -> auth.ScopeCreate
        Some(post_type) -> post.post_type_to_scope(post_type)
      }
      case auth.has_scope(auth_response, required_scope) {
        False -> InsufficientScope |> error_to_response
        True -> {
          case process_micropub_post(post, auth_response, config) {
            Error(err) -> err |> error_to_response
            Ok(location) -> {
              wisp.created() |> response.set_header("location", location)
            }
          }
        }
      }
    }
  }
}

fn form_data_to_micropub_post(
  form_data: List(#(String, String)),
) -> MicropubPost {
  let data = dict.from_list(form_data)
  MicropubPost(
    micropub_type: post.get_field(data, "h", post.PostTypeData),
    content: post.get_field(data, "content", post.ContentData),
    access_token: post.get_field(data, "access_token", fn(s) { s }),
  )
}

fn process_micropub_post(
  micropub_data: MicropubPost,
  auth: AuthResponse,
  config: TwinklePubConfig,
) -> Result(post.Location, http_errors.MicropubError) {
  Ok("https://foo.bar/baz/1")
}

fn handle_q_param(
  _req: Request,
  config: TwinklePubConfig,
  param: String,
) -> Option(Response) {
  case param {
    "config" -> Some(handle_micropub_config(config))
    "syndicate-to" -> Some(handle_syndicate_to(config))
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

fn handle_syndicate_to(config: TwinklePubConfig) -> Response {
  let config =
    MicropubConfig(None, case config.syndicate_to {
      Some(syndicate_to) -> syndicate_to
      None -> []
    })
    |> get_micropub_config_json
    |> string_tree.from_string
  wisp.json_response(config, 200)
}
