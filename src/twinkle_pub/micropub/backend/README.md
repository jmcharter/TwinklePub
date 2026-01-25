# Backends

Storage backends for Micropub posts.

## Available Backends

- **memory** - In-memory storage for testing. Posts are lost on restart.
- **github** - Stores posts as files in a GitHub repository via git_store. Intended for static site generators - posts are serialized to markdown with frontmatter.

## Backend Interface

All backends implement the `Backend` type from `backend.gleam`:

```gleam
Backend(
  get: fn(url) -> Result(PostBody, MicropubError),
  create: fn(post_body) -> Result(url, MicropubError),
  update: fn(url, post_body) -> Result(Nil, MicropubError),
  delete: fn(url) -> Result(Nil, MicropubError),
  capabilities: BackendCapabilities,
)
```

## Adding a New Backend

1. Create a new file in this directory (e.g., `sqlite.gleam`)
2. Implement a `new()` function that returns a `Backend`
3. Handle serialization/deserialization of `PostBody` to your storage format
