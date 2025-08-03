import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/string_tree

import wisp.{type Request, type Response}

import twinkle_pub/auth
import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/http_errors.{InvalidRequest, error_to_response}
import twinkle_pub/micropub.{MicropubConfig, get_micropub_config_json}
import twinkle_pub/micropub/decoders
import twinkle_pub/micropub/post.{type PostBody}
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
      let content_type =
        content_type
        |> string.split_once(";")
        |> result.map(fn(x) { x.0 })
        |> result.unwrap(content_type)
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

fn handle_micropub_form(req: Request, config: TwinklePubConfig) -> Response {
  wisp.log_debug("Handling Form request")
  use form <- wisp.require_form(req)
  let wisp.FormData(values, _files) = form
  echo values
  let new_post = form_data_to_micropub_post(values)
  wisp.log_debug(new_post |> string.inspect)
  case new_post {
    Error(err) -> err |> error_to_response
    Ok(post) -> {
      case process_micropub_post(req, post, config) {
        Error(err) -> err |> error_to_response
        Ok(location) -> {
          wisp.created() |> response.set_header("location", location)
        }
      }
    }
  }
}

fn handle_micropub_json(req: Request, config: TwinklePubConfig) {
  wisp.log_debug("Handling JSON request")
  use json_dynamic <- wisp.require_json(req)
  echo json_dynamic
  let post_result =
    decode.run(json_dynamic, decoders.post_body_decoder())
    |> result.map_error(fn(_) {
      http_errors.InvalidRequest("Unable to decode JSON body")
    })
  post_result |> string.inspect |> wisp.log_debug
  case post_result {
    Error(err) -> err |> error_to_response
    Ok(post) ->
      case process_micropub_post(req, post, config) {
        Error(err) -> err |> error_to_response
        Ok(location) -> {
          wisp.created() |> response.set_header("location", location)
        }
      }
  }
}

pub type FormValue =
  List(#(String, String))

fn form_data_to_micropub_post(
  form_data: FormValue,
) -> Result(PostBody, http_errors.MicropubError) {
  let action = case get_form_value(form_data, "action") {
    Some("update") -> post.Update
    Some("delete") -> post.Delete
    Some("undelete") -> post.Undelete
    _ -> post.Create
  }

  let object_type = case get_form_value(form_data, "h") {
    Some("entry") -> [post.HEntry]
    _ -> [post.HEntry]
  }

  let access_token = get_form_value(form_data, "access_token")
  let properties = build_properties_from_form(form_data)

  Ok(post.PostBody(object_type:, action:, properties:, access_token:))
}

fn build_properties_from_form(form_data: FormValue) -> post.Properties {
  post.Properties(
    content: extract_content(form_data),
    name: extract_simple_values(form_data, "name"),
    summary: extract_simple_values(form_data, "summary"),
    published: extract_simple_values(form_data, "published"),
    updated: extract_simple_values(form_data, "updated"),
    category: extract_simple_values(form_data, "category"),
    in_reply_to: extract_simple_values(form_data, "in-reply-to"),
    like_of: extract_simple_values(form_data, "like-of"),
    repost_of: extract_simple_values(form_data, "repost-of"),
    syndication: extract_simple_values(form_data, "syndication"),
  )
}

fn extract_content(values: FormValue) -> Option(List(post.Content)) {
  case get_form_values(values, "content") {
    [] -> None
    content_values -> Some(list.map(content_values, post.SimpleContent))
  }
}

fn extract_simple_values(values: FormValue, key: String) -> Option(List(String)) {
  case get_form_values(values, key) {
    [] -> None
    items -> Some(items)
  }
}

fn get_form_value(values: FormValue, key: String) -> Option(String) {
  case list.key_find(values, key) {
    Error(_) -> None
    Ok(value) -> Some(value)
  }
}

fn get_form_values(values: FormValue, key: String) -> List(String) {
  values
  |> list.filter(fn(pair) {
    let normalized_key = string.replace(pair.0, "[]", "")
    normalized_key == key
  })
  |> list.map(fn(pair) { pair.1 })
}

fn process_micropub_post(
  req: Request,
  micropub_data: PostBody,
  config: TwinklePubConfig,
) -> Result(post.Location, http_errors.MicropubError) {
  let required_scope = post.action_to_scope(micropub_data.action)
  use _ <- auth.require_auth(
    req,
    micropub_data.access_token,
    required_scope,
    config,
  )
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
