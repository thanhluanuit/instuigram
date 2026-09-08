require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @user  = users(:one)
    @other = users(:two)
  end

  test "when unauthenticated, redirects to sign in and creates no follow" do
    assert_no_difference([ "Follow.count", "EventLog.count" ]) { post user_follow_path(@other) }

    assert_redirected_to new_user_session_path
  end

  test "when authenticated, follows the user and redirects back to their profile" do
    sign_in @user

    assert_difference("Follow.count", 1) { post user_follow_path(@other) }

    assert @user.following?(@other)
    assert_redirected_to user_path(@other)
  end

  test "following logs a single follow_created event" do
    sign_in @user

    assert_difference("EventLog.count", 1) { perform_enqueued_jobs { post user_follow_path(@other) } }

    event_log = EventLog.last
    assert_equal "follow_created", event_log.event_type
    assert_equal Follow.last, event_log.subject
    assert_equal @user, event_log.user
  end

  test "following twice creates no second follow and logs no second event" do
    sign_in @user
    perform_enqueued_jobs { post user_follow_path(@other) }

    assert_no_difference([ "Follow.count", "EventLog.count" ]) do
      perform_enqueued_jobs { post user_follow_path(@other) }
    end
  end

  test "a turbo_stream follow replaces the button and the followers count" do
    sign_in @user

    post user_follow_path(@other), as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][targets=?]", "[data-follow-user-id='#{@other.id}']" do
      assert_select "form[data-follow-user-id=?] button", @other.id.to_s, text: "Following"
    end
    assert_select "turbo-stream[action=replace][target=?]", dom_id(@other, :followers_count) do
      assert_select "li span", text: "1"
    end
  end

  test "a turbo_stream unfollow renders the follow button back" do
    sign_in @user
    post user_follow_path(@other), as: :turbo_stream

    delete user_follow_path(@other), as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][targets=?]", "[data-follow-user-id='#{@other.id}']" do
      assert_select "form[data-follow-user-id=?] button", @other.id.to_s, text: "Follow"
    end
    assert_select "turbo-stream[action=replace][target=?]", dom_id(@other, :followers_count) do
      assert_select "li span", text: "0"
    end
  end

  test "following from the feed returns to the feed" do
    sign_in @user
    get root_path

    post user_follow_path(@other), headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
  end

  test "unfollowing from the feed returns to the feed" do
    sign_in @user
    get root_path
    post user_follow_path(@other)

    delete user_follow_path(@other), headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
  end

  test "following yourself creates no follow and alerts" do
    sign_in @user

    assert_no_difference("Follow.count") { post user_follow_path(@user) }

    assert_equal "You cannot follow yourself.", flash[:alert]
    assert_redirected_to profile_path
  end

  test "unfollowing destroys the follow" do
    sign_in @user
    post user_follow_path(@other)

    assert_difference("Follow.count", -1) { delete user_follow_path(@other) }

    assert_not @user.reload.following?(@other)
    assert_redirected_to user_path(@other)
  end

  test "unfollowing someone you do not follow is a no-op" do
    sign_in @user

    assert_no_difference("Follow.count") { delete user_follow_path(@other) }

    assert_redirected_to user_path(@other)
  end

  test "when unauthenticated, unfollowing redirects to sign in" do
    delete user_follow_path(@other)

    assert_redirected_to new_user_session_path
  end

  test "responds not found when the user to follow is addressed by their database id" do
    sign_in @user

    assert_no_difference("Follow.count") { post user_follow_path(user_id: @other.id) }

    assert_response :not_found
  end
end
