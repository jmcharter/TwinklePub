import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type Comment {
  Comment(id: Int, content: String)
}

pub type Comments =
  List(Comment)

pub type CommentStore {
  CommentStore(comments: List(Comment), next_id: Int)
}

pub type CommentMessage {
  GetComments(reply_with: Subject(Result(Comments, Nil)))
  AddComment(content: String, reply_with: Subject(Result(String, Nil)))
}

fn handle_comment_message(
  state: CommentStore,
  message: CommentMessage,
) -> actor.Next(CommentStore, CommentMessage) {
  case message {
    GetComments(reply_with) -> {
      process.send(reply_with, Ok(state.comments))
      actor.continue(state)
    }
    AddComment(content, reply_with) -> {
      let new_comment = Comment(id: state.next_id, content: content)
      let new_state =
        CommentStore(
          comments: [new_comment, ..state.comments],
          next_id: state.next_id + 1,
        )
      process.send(reply_with, Ok(content))
      actor.continue(new_state)
    }
  }
}

pub fn start_comment_store() {
  let initial_state = CommentStore(comments: [], next_id: 1)
  actor.new(initial_state)
  |> actor.on_message(handle_comment_message)
  |> actor.start()
}

pub fn get_comments(store) {
  actor.call(store, 10_000, fn(subject) { GetComments(subject) })
}

pub fn add_comment(store, comment_body: String) {
  actor.call(store, 10_000, fn(subject) { AddComment(comment_body, subject) })
}
