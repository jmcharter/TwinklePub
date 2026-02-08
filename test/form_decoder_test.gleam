import gleam/option.{Some}
import twinkle_pub/micropub/form_decoder
import twinkle_pub/micropub/post

pub fn simple_note_form_test() {
  let form_data = [#("h", "entry"), #("content", "Hello World")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert [post.HEntry] = post_body.object_type
  let assert post.Create = post_body.action
  let assert Some([post.SimpleContent("Hello World")]) =
    post_body.properties.content
  let assert Some(post.Note) = post_body.post_type
}

pub fn note_with_name_test() {
  let form_data = [
    #("h", "entry"),
    #("name", "Article Title"),
    #("content", "Body"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["Article Title"]) = post_body.properties.name
  // Note: post-type-discovery doesn't use 'name' - articles need explicit type or other cues
  let assert Some(post.Note) = post_body.post_type
}

pub fn simple_categories_test() {
  let form_data = [#("h", "entry"), #("category", "indieweb")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["indieweb"]) = post_body.properties.category
}

pub fn multiple_categories_array_syntax_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Hello"),
    #("category[]", "indieweb"),
    #("category[]", "micropub"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["indieweb", "micropub"]) = post_body.properties.category
}

pub fn action_update_test() {
  let form_data = [
    #("h", "entry"),
    #("action", "update"),
    #("url", "https://example.com/post/1"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert post.Update = post_body.action
}

pub fn action_delete_test() {
  let form_data = [
    #("action", "delete"),
    #("url", "https://example.com/post/1"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert post.Delete = post_body.action
}

pub fn action_undelete_test() {
  let form_data = [
    #("action", "undelete"),
    #("url", "https://example.com/post/1"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert post.Undelete = post_body.action
}

pub fn action_default_create_test() {
  let form_data = [#("h", "entry"), #("content", "Hello")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert post.Create = post_body.action
}

pub fn access_token_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Hello"),
    #("access_token", "secret-token-123"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some("secret-token-123") = post_body.access_token
}

pub fn photo_post_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Check out this photo"),
    #("photo", "https://example.com/photo.jpg"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/photo.jpg"]) =
    post_body.properties.photo
  let assert Some(post.Photo) = post_body.post_type
}

pub fn reply_post_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Great post!"),
    #("in-reply-to", "https://example.com/original"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/original"]) =
    post_body.properties.in_reply_to
  let assert Some(post.Reply) = post_body.post_type
}

pub fn like_post_test() {
  let form_data = [#("h", "entry"), #("like-of", "https://example.com/liked")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/liked"]) = post_body.properties.like_of
  let assert Some(post.Like) = post_body.post_type
}

pub fn repost_post_test() {
  let form_data = [
    #("h", "entry"),
    #("repost-of", "https://example.com/original"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/original"]) =
    post_body.properties.repost_of
  let assert Some(post.Repost) = post_body.post_type
}

pub fn rsvp_post_test() {
  let form_data = [
    #("h", "entry"),
    #("rsvp", "yes"),
    #("in-reply-to", "https://example.com/event"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["yes"]) = post_body.properties.rsvp
  let assert Some(post.RSVP) = post_body.post_type
}

pub fn published_date_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Hello"),
    #("published", "2024-01-15T10:30:00Z"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["2024-01-15T10:30:00Z"]) = post_body.properties.published
}

pub fn summary_post_test() {
  let form_data = [#("h", "entry"), #("summary", "This is a summary")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["This is a summary"]) = post_body.properties.summary
  let assert Some(post.Summary) = post_body.post_type
}

pub fn video_post_test() {
  let form_data = [#("h", "entry"), #("video", "https://example.com/video.mp4")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/video.mp4"]) =
    post_body.properties.video
  let assert Some(post.Video) = post_body.post_type
}

pub fn read_post_test() {
  let form_data = [#("h", "entry"), #("read-of", "https://example.com/book")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/book"]) = post_body.properties.read_of
  let assert Some(post.Read) = post_body.post_type
}

pub fn watch_post_test() {
  let form_data = [#("h", "entry"), #("watch-of", "https://example.com/movie")]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://example.com/movie"]) = post_body.properties.watch_of
  let assert Some(post.Watch) = post_body.post_type
}

pub fn syndication_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Hello"),
    #("syndication", "https://twitter.com/user/status/123"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["https://twitter.com/user/status/123"]) =
    post_body.properties.syndication
}

pub fn empty_form_defaults_to_hentry_test() {
  let form_data = []

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert [post.HEntry] = post_body.object_type
}

pub fn updated_date_test() {
  let form_data = [
    #("h", "entry"),
    #("content", "Updated content"),
    #("updated", "2024-01-20T14:00:00Z"),
  ]

  let assert Ok(post_body) = form_decoder.form_data_to_micropub_post(form_data)

  let assert Some(["2024-01-20T14:00:00Z"]) = post_body.properties.updated
}
