import comment_store.{type CommentMessage}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http.{Get, Post}
import gleam/http/response
import gleam/json
import gleam/list
import gleam/result
import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, comment_store) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["comments"] -> comment(req, comment_store)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) {
  use <- wisp.require_method(req, Get)
  wisp.ok() |> wisp.html_body("Hello, Gleam!")
}

fn comment(
  req: Request,
  comment_store: Subject(CommentMessage),
) -> response.Response(wisp.Body) {
  case req.method {
    Get -> get_comments(comment_store)
    Post -> add_comment(comment_store, req)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn get_comments(
  comment_store: Subject(CommentMessage),
) -> response.Response(wisp.Body) {
  let assert Ok(comments) = comment_store.get_comments(comment_store)
  let string_comments =
    comments
    |> list.reverse
    |> list.fold("", fn(output, comment) {
      output <> comment.content <> "</br>"
    })
  wisp.ok() |> wisp.html_body(string_comments)
}

fn add_comment(
  comment_store: Subject(CommentMessage),
  req: Request,
) -> response.Response(wisp.Body) {
  use json <- wisp.require_json(req)
  let result = {
    use comment <- result.try(decode.run(json, comment_decoder()))
    let object = json.object([#("comment", json.string(comment))])
    let _ = comment_store.add_comment(comment_store, comment)
    Ok(json.to_string(object))
  }
  case result {
    Ok(json) -> {
      wisp.ok() |> wisp.json_body(json)
    }
    Error(_) -> wisp.unprocessable_entity()
  }
}

fn comment_decoder() -> decode.Decoder(String) {
  use comment <- decode.field("comment", decode.string)
  decode.success(comment)
}
