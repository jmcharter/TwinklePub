/// In-memory backend for testing purposes
/// Posts are stored in a simple dict and lost when the process ends
import gleam/dict.{type Dict}
import gleam/int
import gleam/option

import twinkle_pub/http_errors
import twinkle_pub/micropub/backend.{type Backend, Backend, BackendCapabilities}
import twinkle_pub/micropub/post
import twinkle_pub/utils

/// State for the in-memory backend
pub type MemoryState {
  MemoryState(posts: Dict(String, post.PostBody(post.PostTyped)), counter: Int)
}

/// Create a new empty memory state
pub fn new_state() -> MemoryState {
  MemoryState(posts: dict.new(), counter: 0)
}

/// Create a memory backend with mutable state
/// Note: In a real implementation, this would use an actor/process for state
/// For testing, we use a simpler closure-based approach
pub fn new(base_url: String) -> #(Backend, fn() -> MemoryState) {
  // Simple mutable state via closure (for testing only)
  let state = new_state()

  let get_state = fn() { state }

  let backend =
    Backend(
      get: fn(url) { get_post(state, url) },
      create: fn(post_body) { create_post(state, base_url, post_body) },
      update: fn(url, post_body) { update_post(state, url, post_body) },
      delete: fn(url) { delete_post(state, url) },
      capabilities: BackendCapabilities(
        supports_update: True,
        supports_delete: True,
        supports_media: False,
      ),
    )

  #(backend, get_state)
}

fn get_post(
  state: MemoryState,
  url: String,
) -> Result(post.PostBody(post.PostTyped), http_errors.MicropubError) {
  case dict.get(state.posts, url) {
    Ok(post_body) -> Ok(post_body)
    Error(_) -> Error(http_errors.InvalidRequest("Post not found: " <> url))
  }
}

fn create_post(
  state: MemoryState,
  base_url: String,
  post_body: post.PostBody(post.PostTyped),
) -> Result(String, http_errors.MicropubError) {
  let slug = utils.generate_slug(post_body)
  let post_type =
    post_body.post_type |> option.unwrap(post.Note) |> post.post_type_to_string
  let url = base_url <> "/" <> post_type <> "/" <> slug

  // In a real implementation, we'd update state here
  // For now, just return the URL
  let _ = dict.insert(state.posts, url, post_body)
  let _ = int.add(state.counter, 1)

  Ok(url)
}

fn update_post(
  state: MemoryState,
  url: String,
  post_body: post.PostBody(post.PostTyped),
) -> Result(Nil, http_errors.MicropubError) {
  case dict.get(state.posts, url) {
    Ok(_) -> {
      let _ = dict.insert(state.posts, url, post_body)
      Ok(Nil)
    }
    Error(_) -> Error(http_errors.InvalidRequest("Post not found: " <> url))
  }
}

fn delete_post(
  state: MemoryState,
  url: String,
) -> Result(Nil, http_errors.MicropubError) {
  case dict.get(state.posts, url) {
    Ok(_) -> {
      let _ = dict.delete(state.posts, url)
      Ok(Nil)
    }
    Error(_) -> Error(http_errors.InvalidRequest("Post not found: " <> url))
  }
}
