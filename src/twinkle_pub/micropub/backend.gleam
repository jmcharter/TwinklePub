import twinkle_pub/http_errors.{type MicropubError}
import twinkle_pub/micropub/post

pub type BackendCapabilities {
  BackendCapabilities(
    supports_update: Bool,
    supports_delete: Bool,
    supports_media: Bool,
  )
}

/// Implementations provide functions for CRUD operations on posts
pub type Backend {
  Backend(
    /// Get a post by its URL/path
    get: fn(String) -> Result(post.PostBody(post.PostTyped), MicropubError),
    /// Create a new post, returns the URL of the created post
    create: fn(post.PostBody(post.PostTyped)) -> Result(String, MicropubError),
    /// Update an existing post by URL
    update: fn(String, post.PostBody(post.PostTyped)) ->
      Result(Nil, MicropubError),
    /// Delete a post by URL
    delete: fn(String) -> Result(Nil, MicropubError),
    /// Get the capabilities of this backend
    capabilities: BackendCapabilities,
  )
}

/// Default capabilities for a full-featured backend
pub fn full_capabilities() -> BackendCapabilities {
  BackendCapabilities(
    supports_update: True,
    supports_delete: True,
    supports_media: True,
  )
}

/// Read-only capabilities
pub fn readonly_capabilities() -> BackendCapabilities {
  BackendCapabilities(
    supports_update: False,
    supports_delete: False,
    supports_media: False,
  )
}
