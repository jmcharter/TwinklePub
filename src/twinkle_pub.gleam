import gleam/erlang/process
import gleam/string
import mist
import wisp
import wisp/wisp_mist

import twinkle_pub/config
import twinkle_pub/router

pub fn main() -> Nil {
  let config = config.load_config_or_panic()
  wisp.configure_logger()
  wisp.set_logger_level(config.log_level)
  wisp.log_debug("Log level set to: " <> string.inspect(config.log_level))
  let secret_key_base = wisp.random_string(64)

  let handler = fn(req) { router.handle_request(req, config) }

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(9204)
    |> mist.start

  process.sleep_forever()
}
