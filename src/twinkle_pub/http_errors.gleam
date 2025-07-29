import gleam/json
import wisp.{type Response}

pub type MicropubError {
  InvalidRequest(String)
  Unauthorized(String)
  Forbidden
  InsufficientScope
}

pub fn error_to_response(error: MicropubError) -> Response {
  case error {
    InvalidRequest(description) ->
      json_error_response("invalid_request", description, 400)
    Unauthorized(description) ->
      json_error_response("unauthorized", description, 401)
    Forbidden ->
      json_error_response(
        "forbidden",
        "The authenticated user does not have permission to perform this request",
        403,
      )
    InsufficientScope ->
      json_error_response(
        "insufficient_scope",
        "The authenticated user has insufficient scope for this request",
        401,
      )
  }
}

fn json_error_response(
  error_type: String,
  description: String,
  response_code: Int,
) -> Response {
  json.object([
    #("error", json.string(error_type)),
    #("error_description", json.string(description)),
  ])
  |> json.to_string_tree
  |> wisp.json_response(response_code)
}
