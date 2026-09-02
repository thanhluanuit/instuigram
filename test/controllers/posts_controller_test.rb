require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  test "when unauthenticated, redirects to sign in and creates no post" do
    assert_no_difference([ "Post.count", "EventLog.count" ]) { post posts_path, params: valid_post_params }

    assert_redirected_to new_user_session_path
  end

  test "when authenticated with valid params, creates a post owned by current_user and redirects home" do
    sign_in users(:one)

    assert_difference("Post.count", 1) do
      post posts_path, params: valid_post_params(description: "hello #world")
    end

    assert_equal users(:one), Post.last.user
    assert_redirected_to root_path
  end

  test "when authenticated with valid params, enqueues a published_post email to the owner" do
    sign_in users(:one)

    post posts_path, params: valid_post_params

    assert_enqueued_email_with(PostMailer, :published_post, args: [ Post.last ])
  end

  test "when authenticated with valid params, logs a post_created event" do
    sign_in users(:one)

    assert_difference("EventLog.count", 1) do
      perform_enqueued_jobs { post posts_path, params: valid_post_params }
    end

    event_log = EventLog.last
    assert_equal "post_created", event_log.event_type
    assert_equal Post.last, event_log.subject
    assert_equal users(:one), event_log.user
    assert_not_nil event_log.ip_address
  end

  test "when authenticated, ignores a client-supplied user_id and attributes the post to current_user" do
    sign_in users(:one)

    post posts_path, params: {
      post: {
        description: "sneaky",
        user_id: users(:two).id,
        image: fixture_file_upload("test_image.png", "image/png")
      }
    }

    assert_equal users(:one), Post.last.user
  end

  test "when authenticated without an image, creates no post" do
    sign_in users(:one)

    assert_no_difference("Post.count") do
      post posts_path, params: { post: { description: "no image attached" } }
    end
  end

  test "when authenticated without an image, enqueues no email" do
    sign_in users(:one)

    assert_no_enqueued_emails do
      post posts_path, params: { post: { description: "no image attached" } }
    end
  end

  test "is visible to an anonymous visitor" do
    get post_path(posts(:one))

    assert_response :success
  end

  test "when signed in as the post's owner, shows a Delete icon" do
    sign_in users(:one)

    get post_path(posts(:one))

    assert_select "a.delete-icon[aria-label='Delete post']"
  end

  test "when signed in as a different user, hides the Delete icon" do
    sign_in users(:two)

    get post_path(posts(:one))

    assert_select "a.delete-icon", count: 0
  end

  test "when signed in as a different user, shows a follow button in the post header" do
    sign_in users(:two)

    get post_path(posts(:one))

    assert_select ".post-detail .user form[data-follow-user-id=?] button", users(:one).id.to_s, text: "Follow"
  end

  test "when signed in as the post's owner, hides the follow button" do
    sign_in users(:one)

    get post_path(posts(:one))

    assert_select ".post-detail .follow-control", count: 0
  end

  test "when unauthenticated, hides the follow button" do
    get post_path(posts(:one))

    assert_select ".follow-control", count: 0
  end

  test "omits the aside so the post spans the full column" do
    sign_in users(:two)

    get post_path(posts(:one))

    assert_select "aside.app-shell__aside", false
  end

  test "when signed in and not yet reacted, shows an outline heart Like icon" do
    sign_in users(:one)

    get post_path(posts(:two))

    assert_select "a.reaction-icon[aria-label='Like']"
    assert_select "a.reaction-icon.liked", count: 0
  end

  test "when signed in and already reacted, shows a filled heart Unlike icon" do
    sign_in users(:two)

    get post_path(posts(:one))

    assert_select "a.reaction-icon.liked[aria-label='Unlike']"
  end

  test "when unauthenticated, shows no reaction icon" do
    get post_path(posts(:one))

    assert_select "a.reaction-icon", count: 0
  end

  test "shows the post's existing comments" do
    get post_path(posts(:one))

    assert_select ".comment .text", text: comments(:one).body
  end

  test "when signed in as the comment's owner, shows a delete icon for that comment" do
    sign_in users(:two)

    get post_path(posts(:one))

    assert_select "a.delete-comment-icon[aria-label='Delete comment']"
  end

  test "when signed in as a different user, hides the comment's delete icon" do
    sign_in users(:one)

    get post_path(posts(:one))

    assert_select "a.delete-comment-icon", count: 0
  end

  test "when signed in, shows a comment form" do
    sign_in users(:one)

    get post_path(posts(:one))

    assert_select "form[action=?]", post_comments_path(posts(:one))
  end

  test "when unauthenticated, hides the comment form" do
    get post_path(posts(:one))

    assert_select "form[action=?]", post_comments_path(posts(:one)), count: 0
  end

  test "when unauthenticated, redirects to sign in and does not delete the post" do
    assert_no_difference([ "Post.count", "EventLog.count" ]) { delete post_path(posts(:one)) }

    assert_redirected_to new_user_session_path
  end

  test "when signed in as the post's owner, deletes the post and redirects to their profile" do
    sign_in users(:one)

    assert_difference("Post.count", -1) { delete post_path(posts(:one)) }

    assert_redirected_to profile_path
  end

  test "when signed in as the post's owner, logs a post_destroyed event" do
    sign_in users(:one)

    assert_difference("EventLog.count", 1) do
      perform_enqueued_jobs { delete post_path(posts(:one)) }
    end

    event_log = EventLog.last
    assert_equal "post_destroyed", event_log.event_type
    assert_equal "Post", event_log.subject_type
    assert_equal posts(:one).id, event_log.subject_id
    assert_equal users(:one), event_log.user
  end

  test "when signed in as a different user, responds not found and does not delete the post" do
    sign_in users(:two)

    assert_no_difference("EventLog.count") { delete post_path(posts(:one)) }

    assert_response :not_found
    assert Post.exists?(posts(:one).id)
  end

  test "addresses a post by key rather than by id" do
    get post_path(posts(:one))

    assert_response :success
    assert_equal "/posts/#{posts(:one).key}", path
  end

  test "responds not found when a post is requested by its database id" do
    get post_path(id: posts(:one).id)

    assert_response :not_found
  end

  test "when requested from the post_modal turbo frame, renders the post as a popup" do
    sign_in users(:one)

    get post_path(posts(:one)), headers: { "Turbo-Frame" => "post_modal" }

    assert_response :success
    assert_select "turbo-frame#post_modal .post-modal .post-detail"
    assert_select "turbo-frame##{dom_id(posts(:one), :modal_reaction)}"
    assert_select "turbo-frame##{dom_id(posts(:one), :reaction)}", count: 0
  end

  test "when requested as a full page, renders the post detail outside a popup" do
    sign_in users(:one)

    get post_path(posts(:one))

    assert_select ".post-modal", count: 0
    assert_select "turbo-frame##{dom_id(posts(:one), :reaction)}"
  end

  private

  def valid_post_params(description: "a caption")
    {
      post: {
        description: description,
        image: fixture_file_upload("test_image.png", "image/png")
      }
    }
  end
end
