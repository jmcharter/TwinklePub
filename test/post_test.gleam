import gleam/option.{None, Some}
import twinkle_pub/micropub/post

pub fn post_type_to_string_article_test() {
  let assert "article" = post.post_type_to_string(post.Article)
}

pub fn post_type_to_string_like_test() {
  let assert "like" = post.post_type_to_string(post.Like)
}

pub fn post_type_to_string_note_test() {
  let assert "note" = post.post_type_to_string(post.Note)
}

pub fn post_type_to_string_photo_test() {
  let assert "photo" = post.post_type_to_string(post.Photo)
}

pub fn post_type_to_string_read_test() {
  let assert "read" = post.post_type_to_string(post.Read)
}

pub fn post_type_to_string_reply_test() {
  let assert "reply" = post.post_type_to_string(post.Reply)
}

pub fn post_type_to_string_repost_test() {
  let assert "repost" = post.post_type_to_string(post.Repost)
}

pub fn post_type_to_string_rsvp_test() {
  let assert "rsvp" = post.post_type_to_string(post.RSVP)
}

pub fn post_type_to_string_summary_test() {
  let assert "summary" = post.post_type_to_string(post.Summary)
}

pub fn post_type_to_string_video_test() {
  let assert "video" = post.post_type_to_string(post.Video)
}

pub fn post_type_to_string_watch_test() {
  let assert "watch" = post.post_type_to_string(post.Watch)
}

pub fn action_to_scope_create_test() {
  let assert post.ScopeCreate = post.action_to_scope(post.Create)
}

pub fn action_to_scope_update_test() {
  let assert post.ScopeUpdate = post.action_to_scope(post.Update)
}

pub fn action_to_scope_delete_test() {
  let assert post.ScopeDelete = post.action_to_scope(post.Delete)
}

pub fn action_to_scope_undelete_test() {
  let assert post.ScopeCreate = post.action_to_scope(post.Undelete)
}

pub fn with_post_type_note_default_test() {
  let post_body = post.new()
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Note) = typed_post.post_type
}

pub fn with_post_type_photo_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      photo: Some(["https://example.com/photo.jpg"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Photo) = typed_post.post_type
}

pub fn with_post_type_like_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      like_of: Some(["https://example.com/liked-post"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Like) = typed_post.post_type
}

pub fn with_post_type_reply_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      in_reply_to: Some(["https://example.com/replied-post"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Reply) = typed_post.post_type
}

pub fn with_post_type_repost_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      repost_of: Some(["https://example.com/reposted-post"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Repost) = typed_post.post_type
}

pub fn with_post_type_rsvp_yes_test() {
  let props = post.Properties(..post.empty_properties(), rsvp: Some(["yes"]))
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.RSVP) = typed_post.post_type
}

pub fn with_post_type_rsvp_no_test() {
  let props = post.Properties(..post.empty_properties(), rsvp: Some(["no"]))
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.RSVP) = typed_post.post_type
}

pub fn with_post_type_rsvp_maybe_test() {
  let props = post.Properties(..post.empty_properties(), rsvp: Some(["maybe"]))
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.RSVP) = typed_post.post_type
}

pub fn with_post_type_rsvp_interested_test() {
  let props =
    post.Properties(..post.empty_properties(), rsvp: Some(["interested"]))
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.RSVP) = typed_post.post_type
}

pub fn with_post_type_rsvp_invalid_test() {
  let props =
    post.Properties(..post.empty_properties(), rsvp: Some(["invalid"]))
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Note) = typed_post.post_type
}

pub fn with_post_type_read_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      read_of: Some(["https://example.com/book"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Read) = typed_post.post_type
}

pub fn with_post_type_watch_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      watch_of: Some(["https://example.com/video"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Watch) = typed_post.post_type
}

pub fn with_post_type_summary_test() {
  let props =
    post.Properties(..post.empty_properties(), summary: Some(["Summary text"]))
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Summary) = typed_post.post_type
}

pub fn with_post_type_video_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      video: Some(["https://example.com/video.mp4"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.Video) = typed_post.post_type
}

pub fn with_post_type_priority_rsvp_over_like_test() {
  let props =
    post.Properties(
      ..post.empty_properties(),
      rsvp: Some(["yes"]),
      like_of: Some(["https://example.com/liked"]),
    )
  let post_body = post.PostBody(..post.new(), properties: props)
  let typed_post = post.with_post_type(post_body)

  let assert Some(post.RSVP) = typed_post.post_type
}

pub fn new_post_has_hentry_type_test() {
  let post_body = post.new()

  let assert [post.HEntry] = post_body.object_type
}

pub fn new_post_has_create_action_test() {
  let post_body = post.new()

  let assert post.Create = post_body.action
}

pub fn new_post_has_empty_properties_test() {
  let post_body = post.new()

  let assert None = post_body.properties.content
  let assert None = post_body.properties.name
  let assert None = post_body.properties.category
}

pub fn empty_properties_all_none_test() {
  let props = post.empty_properties()

  let assert None = props.content
  let assert None = props.name
  let assert None = props.summary
  let assert None = props.published
  let assert None = props.updated
  let assert None = props.category
  let assert None = props.in_reply_to
  let assert None = props.rsvp
  let assert None = props.like_of
  let assert None = props.video
  let assert None = props.photo
  let assert None = props.repost_of
  let assert None = props.read_of
  let assert None = props.watch_of
  let assert None = props.syndication
}
