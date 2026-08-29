require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  test "when unauthenticated, redirects to sign in and creates no comment" do
    assert_no_difference([ "Comment.count", "EventLog.count" ]) do
      post post_comments_path(posts(:one)), params: { comment: { body: "Nice!" } }
    end

    assert_redirected_to new_user_session_path
  end

  test "when authenticated with a valid body, creates a comment owned by current_user and redirects to the post" do
    sign_in users(:one)

    assert_difference("Comment.count", 1) do
      post post_comments_path(posts(:two)), params: { comment: { body: "Nice!" } }
    end

    comment = Comment.last
    assert_equal users(:one), comment.user
    assert_equal posts(:two), comment.post
    assert_equal "Nice!", comment.body
    assert_redirected_to post_path(posts(:two))
  end

  test "when authenticated with a valid body, logs a comment_created event" do
    sign_in users(:one)

    assert_difference("EventLog.count", 1) do
      perform_enqueued_jobs { post post_comments_path(posts(:two)), params: { comment: { body: "Nice!" } } }
    end

    event_log = EventLog.last
    assert_equal "comment_created", event_log.event_type
    assert_equal Comment.last, event_log.subject
    assert_equal users(:one), event_log.user
  end

  test "when authenticated with a blank body, creates no comment" do
    sign_in users(:one)

    assert_no_difference([ "Comment.count", "EventLog.count" ]) do
      post post_comments_path(posts(:two)), params: { comment: { body: "" } }
    end
  end

  test "when a blank body is submitted as a turbo stream, re-renders in place instead of redirecting" do
    sign_in users(:one)

    post post_comments_path(posts(:two)), params: { comment: { body: "" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:two), :comment_form)
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:two), :feed_comment_form)
  end

  test "a rejected comment sends the reason back in the replaced form" do
    sign_in users(:one)

    post post_comments_path(posts(:two)), params: { comment: { body: "" } }, as: :turbo_stream

    assert_select "turbo-stream .comment-form__error", text: /Body can't be blank/
  end

  test "a successful comment leaves the replaced form blank and error-free" do
    sign_in users(:one)

    post post_comments_path(posts(:two)), params: { comment: { body: "Nice!" } }, as: :turbo_stream

    assert_select ".comment-form__error", count: 0
    assert_select "turbo-stream input##{dom_id(posts(:two), :feed_comment_form_body)}[value]", count: 0
  end

  test "when asked for a turbo stream, creating a comment refreshes the list, the form, and the count" do
    sign_in users(:one)

    post post_comments_path(posts(:two)), params: { comment: { body: "Nice!" } }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:two), :comments)
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:two), :comment_form)
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:two), :comments_count)
    assert_match "Nice!", @response.body
    assert_match "2 comments", @response.body
  end

  test "when asked for a turbo stream, deleting a comment refreshes the list and the count" do
    sign_in users(:two)

    delete comment_path(comments(:one)), as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:one), :comments)
    assert_select "turbo-stream[action=replace][target=?]", dom_id(posts(:one), :comments_count)
    assert_match "No comments yet.", @response.body
    assert_match "0 comments", @response.body
  end

  test "when unauthenticated, redirects to sign in and does not delete a comment" do
    assert_no_difference("Comment.count") { delete comment_path(comments(:one)) }

    assert_redirected_to new_user_session_path
  end

  test "when signed in as the comment's owner, deletes the comment and redirects to the post" do
    sign_in users(:two)

    assert_difference("Comment.count", -1) { delete comment_path(comments(:one)) }

    assert_redirected_to post_path(posts(:one))
  end

  test "when signed in as a different user, responds not found and does not delete the comment" do
    sign_in users(:one)

    delete comment_path(comments(:one))

    assert_response :not_found
    assert Comment.exists?(comments(:one).id)
  end
end
