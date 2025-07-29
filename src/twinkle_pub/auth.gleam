import gleam/dict
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string
import twinkle_pub/config.{type TwinklePubConfig}

import wisp.{type Request}

import twinkle_pub/http_errors.{type MicropubError, Unauthorized}

pub type AuthResponse {
  AuthResponse(access_token: String, me: String, scope: String)
}

fn auth_token_decoder() -> decode.Decoder(AuthResponse) {
  use access_token <- decode.field("access_token", decode.string)
  use me <- decode.field("me", decode.string)
  use scope <- decode.field("scope", decode.string)
  decode.success(AuthResponse(access_token:, me:, scope:))
}

pub fn verify_access_token(
  req: Request,
  config: TwinklePubConfig,
) -> Result(AuthResponse, MicropubError) {
  case get_authorization_token(req) {
    Ok(token) -> verify_token_with_endpoint(token, config)
    Error(_) ->
      Error(Unauthorized("No access token was provided in the request"))
  }
}

fn get_authorization_token(req: Request) -> Result(String, Nil) {
  req.headers
  |> dict.from_list
  |> dict.get("authorization")
  |> result.try(fn(auth) {
    case string.starts_with(auth, "Bearer ") {
      True -> Ok(string.drop_start(auth, 7))
      False -> Error(Nil)
    }
  })
}

fn verify_token_with_endpoint(
  token: String,
  config: TwinklePubConfig,
) -> Result(AuthResponse, MicropubError) {
  use req <- result.try(
    request.to(config.token_endpoint)
    |> result.map_error(fn(_) { Unauthorized("Invalid token endpoint") }),
  )
  use res <- result.try(
    req
    |> request.prepend_header("accept", "application/json")
    |> request.prepend_header("authorization", "Bearer " <> token)
    |> httpc.send
    |> result.map_error(fn(err) {
      wisp.log_error(string.inspect(err))
      Unauthorized("Failed to verify token")
    }),
  )

  case res.status {
    200 ->
      json.parse(res.body, auth_token_decoder())
      |> result.map_error(fn(err) {
        wisp.log_error(string.inspect(err))
        Unauthorized("Invalid token response")
      })
    _ -> Error(Unauthorized("Failed to verify token"))
  }
}
