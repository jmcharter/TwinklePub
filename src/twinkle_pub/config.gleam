import envoy
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import wisp

import twinkle_pub/micropub.{type SyndicateTarget, syndicate_target_decoder}
import twinkle_pub/micropub/backend
import twinkle_pub/micropub/backend/github

pub type TwinklePubConfig {
  TwinklePubConfig(
    token_endpoint: String,
    me: String,
    media_endpoint: Option(String),
    syndicate_to: Option(List(SyndicateTarget)),
    log_level: wisp.LogLevel,
    backend: backend.Backend,
  )
}

pub type ConfigError {
  MissingRequiredEnvVar(name: String)
  InvalidSyndicateToJson(json.DecodeError)
}

pub fn load_twinkle_config() -> Result(TwinklePubConfig, ConfigError) {
  use token_endpoint <- result.try(require_env("TOKEN_ENDPOINT"))
  use me <- result.try(require_env("ME"))
  use syndicate_to <- result.try(load_syndicate_to())

  let media_endpoint = envoy.get("MEDIA_ENDPOINT") |> option.from_result
  let log_level = parse_log_level()

  use github_owner <- result.try(require_env("GITHUB_OWNER"))
  use github_repo <- result.try(require_env("GITHUB_REPO"))
  use github_token <- result.try(require_env("GITHUB_TOKEN"))
  use github_base_path <- result.try(require_env("GITHUB_BASE_PATH"))

  let github_config =
    github.GitHubConfig(
      owner: github_owner,
      repo: github_repo,
      token: github_token,
      base_path: github_base_path,
      base_url: "https://wibble.wobble",
    )
  let backend = github.new(github_config)

  Ok(TwinklePubConfig(
    token_endpoint:,
    me:,
    media_endpoint:,
    syndicate_to:,
    log_level:,
    backend:,
  ))
}

fn require_env(name: String) -> Result(String, ConfigError) {
  envoy.get(name)
  |> result.map_error(fn(_) { MissingRequiredEnvVar(name) })
}

fn load_syndicate_to() -> Result(Option(List(SyndicateTarget)), ConfigError) {
  case envoy.get("SYNDICATE_TO") {
    Ok(json_string) ->
      case string.trim(json_string) {
        "" -> Ok(None)
        trimmed_json ->
          json.parse(trimmed_json, decode.list(syndicate_target_decoder()))
          |> result.map(Some)
          |> result.map_error(InvalidSyndicateToJson)
      }
    Error(_) -> Ok(None)
  }
}

fn parse_log_level() -> wisp.LogLevel {
  case envoy.get("LOG_LEVEL") {
    Ok(level) ->
      case string.lowercase(level) {
        "debug" -> wisp.DebugLevel
        "info" -> wisp.InfoLevel
        "notice" -> wisp.NoticeLevel
        "warn" | "warning" -> wisp.WarningLevel
        "error" -> wisp.ErrorLevel
        "critical" -> wisp.CriticalLevel
        "alert" -> wisp.AlertLevel
        "emergency" -> wisp.EmergencyLevel
        _ -> wisp.InfoLevel
      }
    Error(_) -> wisp.InfoLevel
  }
}

pub fn load_config_or_panic() -> TwinklePubConfig {
  case load_twinkle_config() {
    Ok(config) -> config
    Error(MissingRequiredEnvVar(name)) ->
      panic as { "Missing required environment variable: " <> name }
    Error(InvalidSyndicateToJson(json_error)) ->
      panic as {
        "Invalid JSON for SYNDICATE_TO: " <> string.inspect(json_error)
      }
  }
}
