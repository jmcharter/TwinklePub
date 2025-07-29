import gleam/json
import wisp.{type Response}

pub type MicropubError {
  InvalidRequest(String)
}

pub fn error_to_response(error: MicropubError) -> Response {
  case error {
    InvalidRequest(description) ->
      json.object([
        #("error", json.string("invalid_request")),
        #("error_description", json.string(description)),
      ])
      |> json.to_string_tree
      |> wisp.json_response(400)
  }
}
