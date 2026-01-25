/// GitHub-based backend using git_store
/// Stores posts as files in a GitHub repository, intended for static site generators.
/// Posts are serialized to markdown with YAML frontmatter.
import gleam/list
import gleam/option
import gleam/result
import gleam/string

import git_store

import twinkle_pub/http_errors
import twinkle_pub/micropub/backend.{type Backend, Backend}
import twinkle_pub/micropub/post
import twinkle_pub/utils

pub type GitHubConfig {
  GitHubConfig(
    owner: String,
    repo: String,
    token: String,
    /// Path within the repo where posts are stored (e.g., "content/posts")
    base_path: String,
    /// Base URL for the published site (e.g., "https://example.com")
    base_url: String,
  )
}

/// Create a new GitHub backend
pub fn new(config: GitHubConfig) -> Backend {
  let git_config = git_store.new_config(config.owner, config.repo, config.token)

  Backend(
    get: fn(url) { get_post(git_config, config, url) },
    create: fn(post_body) { create_post(git_config, config, post_body) },
    update: fn(url, post_body) { update_post(git_config, config, url, post_body) },
    delete: fn(url) { delete_post(git_config, config, url) },
    capabilities: backend.full_capabilities(),
  )
}

fn get_post(
  _git_config: git_store.GitHubConfig,
  _config: GitHubConfig,
  url: String,
) -> Result(post.PostBody(post.PostTyped), http_errors.MicropubError) {
  // TODO: Implement fetching post from GitHub
  // 1. Convert URL to file path
  // 2. Fetch file content via git_store.get_file
  // 3. Parse markdown frontmatter to PostBody
  Error(http_errors.ServerError(
    "GitHub backend get not implemented for: " <> url,
  ))
}

fn create_post(
  git_config: git_store.GitHubConfig,
  config: GitHubConfig,
  post_body: post.PostBody(post.PostTyped),
) -> Result(String, http_errors.MicropubError) {
  let slug = utils.generate_slug(post_body)
  let post_type =
    post_body.post_type |> option.unwrap(post.Note) |> post.post_type_to_string
  let file_path = config.base_path <> "/" <> post_type <> "/" <> slug <> ".md"
  let url = config.base_url <> "/" <> post_type <> "/" <> slug

  let content = post_to_markdown(post_body)

  git_store.create_file(git_config, file_path, content)
  |> result.map(fn(_) { url })
  |> result.map_error(fn(err) {
    http_errors.ServerError("Failed to create post: " <> string.inspect(err))
  })
}

fn update_post(
  _git_config: git_store.GitHubConfig,
  _config: GitHubConfig,
  url: String,
  _post_body: post.PostBody(post.PostTyped),
) -> Result(Nil, http_errors.MicropubError) {
  // TODO: Implement via git_store.update_file
  Error(http_errors.ServerError(
    "GitHub backend update not implemented for: " <> url,
  ))
}

fn delete_post(
  _git_config: git_store.GitHubConfig,
  _config: GitHubConfig,
  url: String,
) -> Result(Nil, http_errors.MicropubError) {
  // TODO: Implement via git_store.delete_file
  Error(http_errors.ServerError(
    "GitHub backend delete not implemented for: " <> url,
  ))
}

/// Convert a PostBody to markdown with YAML frontmatter
fn post_to_markdown(post_body: post.PostBody(post.PostTyped)) -> String {
  let props = post_body.properties

  // Build frontmatter
  let frontmatter = "---\n"

  // Add name/title if present
  let frontmatter = case props.name {
    option.Some([name, ..]) -> frontmatter <> "title: \"" <> name <> "\"\n"
    _ -> frontmatter
  }

  // Add published date if present
  let frontmatter = case props.published {
    option.Some([date, ..]) -> frontmatter <> "date: " <> date <> "\n"
    _ -> frontmatter
  }

  // Add categories if present
  let frontmatter = case props.category {
    option.Some(categories) ->
      frontmatter
      <> "tags:\n"
      <> string.join(list.map(categories, fn(c) { "  - " <> c }), "\n")
      <> "\n"
    _ -> frontmatter
  }

  let frontmatter = frontmatter <> "---\n\n"

  // Add content
  let content = case props.content {
    option.Some([post.SimpleContent(text), ..]) -> text
    option.Some([post.RichContent(html: option.Some(html), value: _), ..]) ->
      html
    option.Some([post.RichContent(html: _, value: option.Some(text)), ..]) ->
      text
    _ -> ""
  }

  frontmatter <> content
}
