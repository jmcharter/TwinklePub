import gleam/dict
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/string_tree

import wisp.{type Request, type Response}

import twinkle_pub/auth
import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/http_errors.{
  InsufficientScope, InvalidRequest, error_to_response,
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
        "application/json" -> handle_micropub_json(req, config)
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
  wisp.log_debug("Handling Form request")
  use form <- wisp.require_form(req)
  let wisp.FormData(values, _files) = form
  echo values
  let new_post = form_data_to_micropub_post(values)
  wisp.log_debug(new_post |> string.inspect)
  case process_micropub_post(req, new_post, config) {
    Error(err) -> err |> error_to_response
    Ok(location) -> {
      wisp.created() |> response.set_header("location", location)
    }
  }
}

fn handle_micropub_json(req: Request, config: TwinklePubConfig) {
  wisp.log_debug("Handling JSON request")
  use json_dynamic <- wisp.require_json(req)
  echo json_dynamic
  let new_post = decode.run(json_dynamic, micropub_json_decoder())
  let new_post = result.unwrap(new_post, post.empty_post())
  wisp.log_debug(new_post |> string.inspect)
  case process_micropub_post(req, new_post, config) {
    Error(err) -> err |> error_to_response
    Ok(location) -> {
      wisp.created() |> response.set_header("location", location)
    }
  }
}

fn micropub_json_decoder() -> decode.Decoder(MicropubPost) {
  use post_type <- decode.then(post_type_decoder())
  use content <- decode.subfield(
    ["properties", "content"],
    decode.list(decode.string)
      |> decode.map(fn(content_list) {
        case content_list {
          [first, ..] -> Some(post.ContentData(first))
          [] -> None
        }
      }),
  )
  use access_token <- decode.optional_field(
    "access_token",
    None,
    decode.optional(decode.string),
  )
  decode.success(MicropubPost(micropub_type: post_type, content:, access_token:))
}

fn post_type_decoder() -> decode.Decoder(post.PostTypeData) {
  decode.field("type", decode.list(decode.string), fn(type_list) {
    case type_list {
      [first, ..] -> decode.success(post.PostTypeData(first))
      [] -> decode.success(post.PostTypeData("h-entry"))
    }
  })
}

fn form_data_to_micropub_post(
  form_data: List(#(String, String)),
) -> MicropubPost {
  let data = dict.from_list(form_data)
  MicropubPost(
    micropub_type: option.unwrap(
      post.get_field(data, "h", post.PostTypeData),
      post.PostTypeData("create"),
    ),
    content: post.get_field(data, "content", post.ContentData),
    access_token: post.get_field(data, "access_token", fn(s) { s }),
  )
}

fn process_micropub_post(
  req: Request,
  micropub_data: MicropubPost,
  config: TwinklePubConfig,
) -> Result(post.Location, http_errors.MicropubError) {
  case auth.verify_access_token(req, micropub_data.access_token, config) {
    Error(err) -> err |> error_to_response
    Ok(auth_response) -> {
      let required_scope = post.post_type_to_scope(micropub_data.micropub_type)
      case auth.has_scope(auth_response, required_scope) {
        False -> InsufficientScope |> error_to_response
        True -> {
          wisp.created()
          |> response.set_header("location", "https://foo.bar/baz/1")
        }
      }
    }
  }
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
