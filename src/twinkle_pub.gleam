import comment_store
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

import router

pub fn main() -> Nil {
  let assert Ok(comment_store) = comment_store.start_comment_store()
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let handler = fn(req) { router.handle_request(req, comment_store.data) }

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(9204)
    |> mist.start

  process.sleep_forever()
}
