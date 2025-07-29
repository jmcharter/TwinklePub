import envoy
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import twinkle_pub/micropub.{type SyndicateTarget, syndicate_target_decoder}

pub type TwinklePubConfig {
  TwinklePubConfig(
    token_endpoint: String,
    media_endpoint: Option(String),
    syndicate_to: Option(List(SyndicateTarget)),
  )
}

pub type ConfigError {
  InvalidSyndicateToJson(json.DecodeError)
}

pub fn load_twinkle_config() -> Result(TwinklePubConfig, ConfigError) {
  let token_endpoint = case envoy.get("TOKEN_ENDPOINT") {
    Ok(endpoint) -> endpoint
    Error(_) -> panic as "TOKEN_ENDPOINT environment variable is required"
  }

  let media_endpoint = case envoy.get("MEDIA_ENDPOINT") {
    Ok(endpoint) -> Some(endpoint)
    Error(_) -> None
  }

  let syndicate_to = case envoy.get("SYNDICATE_TO") {
    Ok(json_string) ->
      case string.trim(json_string) {
        "" -> Ok(None)
        trimmed_json ->
          parse_syndicate_to_json(trimmed_json)
          |> result.map(Some)
      }
    Error(_) -> Ok(None)
  }

  use syndicate_to <- result.try(syndicate_to)
  Ok(TwinklePubConfig(token_endpoint, media_endpoint, syndicate_to))
}

fn parse_syndicate_to_json(
  json_string: String,
) -> Result(List(SyndicateTarget), ConfigError) {
  json.parse(json_string, decode.list(syndicate_target_decoder()))
  |> result.map_error(InvalidSyndicateToJson)
}

pub fn load_config_or_panic() -> TwinklePubConfig {
  case load_twinkle_config() {
    Ok(config) -> config
    Error(InvalidSyndicateToJson(json_error)) -> {
      let message =
        "Invalid JSON detected for environment variable SYNDICATE_TO: "
        <> string.inspect(json_error)
      panic as message
    }
  }
}
