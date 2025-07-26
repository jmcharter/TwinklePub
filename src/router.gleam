import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use _req <- web.middleware(req)
  let body = "<h1>Hello, Gleam!</h1>"
  wisp.html_response(body, 200)
}
