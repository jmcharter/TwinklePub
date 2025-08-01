import gleam/dict
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}

import wisp.{type Request}

import twinkle_pub/config.{type TwinklePubConfig}
import twinkle_pub/http_errors.{type MicropubError, InvalidRequest, Unauthorized}

pub type AuthResponse {
  AuthResponse(
    me: String,
    client_id: String,
    scopes: Scopes,
    issued_at: Timestamp,
    nonce: Int,
  )
}

pub type Scope {
  ScopeCreate
  ScopeDraft
  ScopeUpdate
  ScopeDelete
  ScopeMedia
  ScopeProfile
}

pub type Scopes =
  List(Scope)

pub fn string_to_scope(scope: String) -> Result(Scope, Nil) {
  case scope {
    "create" -> Ok(ScopeCreate)
    "draft" -> Ok(ScopeDraft)
    "update" -> Ok(ScopeUpdate)
    "delete" -> Ok(ScopeDelete)
    "media" -> Ok(ScopeMedia)
    "profile" -> Ok(ScopeProfile)
    _ -> Error(Nil)
  }
}

fn parse_scopes(scopes: String) -> Result(Scopes, String) {
  scopes
  |> string.split(" ")
  |> list.try_map(string_to_scope)
  |> result.map_error(fn(_) { "Invalid scope in: " <> scopes })
}

fn scope_decoder() -> decode.Decoder(Scopes) {
  use scope_string <- decode.then(decode.string)
  case parse_scopes(scope_string) {
    Error(_) -> decode.failure([ScopeCreate], "Scopes")
    Ok(scopes) -> decode.success(scopes)
  }
}

fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use unix_seconds <- decode.then(decode.int)
  timestamp.from_unix_seconds(unix_seconds)
  |> decode.success
}

fn auth_token_decoder() -> decode.Decoder(AuthResponse) {
  use me <- decode.field("me", decode.string)
  use client_id <- decode.field("client_id", decode.string)
  use scopes <- decode.field("scope", scope_decoder())
  use issued_at <- decode.field("issued_at", timestamp_decoder())
  use nonce <- decode.field("nonce", decode.int)
  decode.success(AuthResponse(me:, client_id:, scopes:, issued_at:, nonce:))
}

type ErrorResponse {
  ErrorResponse(error: String, error_description: String)
}

fn error_response_decoder() {
  use error <- decode.field("error", decode.string)
  use error_description <- decode.field("error_description", decode.string)
  decode.success(ErrorResponse(error:, error_description:))
}

pub fn verify_access_token(
  req: Request,
  body_access_token: Option(String),
  config: TwinklePubConfig,
) -> Result(AuthResponse, MicropubError) {
  case get_authorization_token(req), body_access_token {
    Ok(token), None -> verify_token_with_endpoint(token, config)
    Error(_), Some(token) -> verify_token_with_endpoint(token, config)
    Error(_), None ->
      Error(Unauthorized("No access token was provided in the request"))
    Ok(_), Some(_) ->
      Error(InvalidRequest("Access token included in both header and body"))
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
    400 -> {
      case json.parse(res.body, error_response_decoder()) {
        Ok(error_response) -> {
          wisp.log_error(
            "Error: "
            <> error_response.error
            <> " - "
            <> error_response.error_description,
          )
          Error(Unauthorized(error_response.error_description))
        }
        Error(parse_err) -> {
          wisp.log_error(
            "Failed to parse error response: " <> string.inspect(parse_err),
          )
          wisp.log_error("Raw response: " <> string.inspect(res))
          Error(Unauthorized(
            "There was a problem with the authentication endpoint",
          ))
        }
      }
    }
    _ ->
      Error(Unauthorized("There was a problem with the authentication endpoint"))
  }
}

pub fn has_scope(auth_response: AuthResponse, target_scope: Scope) -> Bool {
  list.contains(auth_response.scopes, target_scope)
}
