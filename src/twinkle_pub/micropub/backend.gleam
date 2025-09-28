import gleam/option
import twinkle_pub/http_errors
import twinkle_pub/micropub/post

import git_store

pub type Backend {
  Backend(
    get: fn(String) ->
      Result(post.PostBody(post.PostTyped), http_errors.MicropubError),
    create: fn(post.PostBody(post.PostTyped)) ->
      Result(String, http_errors.MicropubError),
  )
}

pub fn github_backend(owner: String, token: String, repo: String) {
  let config = git_store.new_config(owner, repo, token)
  // Backend(
  //   get: fn(path: String) { git_store.get_file(config, path) },
  //   create: fn(post_body: post.PostBody(post.PostTyped)) {
  //     let name = case post_body.properties.name {
  //       option.None -> todo
  //       option.Some(name) -> name
  //     }
  //     git_store.create_file(config, post_body.properties.name)
  //   },
  // )
  todo
}
