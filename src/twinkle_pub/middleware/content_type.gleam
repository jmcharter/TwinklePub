import gleam/http/request
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import wisp.{type Request, type Response}

import twinkle_pub/http_errors

pub type ContentType {
  ApplicationJson
  FormUrlEncoded
  MultipartFormData
}

/// Parse the content-type header from a request
pub fn parse_content_type(req: Request) -> Option(ContentType) {
  case request.get_header(req, "content-type") {
    Error(_) -> None
    Ok(content_type) -> {
      // Strip charset and other parameters (e.g., "application/json; charset=utf-8")
      let base_type =
        content_type
        |> string.split_once(";")
        |> result.map(fn(x) { x.0 })
        |> result.unwrap(content_type)
        |> string.trim

      case base_type {
        "application/json" -> Some(ApplicationJson)
        "application/x-www-form-urlencoded" -> Some(FormUrlEncoded)
        "multipart/form-data" -> Some(MultipartFormData)
        _ -> None
      }
    }
  }
}

/// Handle Micropub POST requests with appropriate content-type routing
pub fn require_micropub_content_type(
  req: Request,
  handle_json: fn() -> Response,
  handle_form: fn() -> Response,
) -> Response {
  case parse_content_type(req) {
    Some(ApplicationJson) -> handle_json()
    Some(FormUrlEncoded) | Some(MultipartFormData) -> handle_form()
    None ->
      case request.get_header(req, "content-type") {
        Error(_) ->
          http_errors.InvalidRequest(
            "Missing 'content-type' header in request",
          )
          |> http_errors.error_to_response
        Ok(ct) ->
          http_errors.InvalidRequest("Content type " <> ct <> " not supported")
          |> http_errors.error_to_response
      }
  }
}
