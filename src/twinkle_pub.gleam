import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

import router

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(9204)
    |> mist.start

  process.sleep_forever()
}
