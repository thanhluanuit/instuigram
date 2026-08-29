require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  TURBO_NAVIGATION_ACCEPT = "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"

  test "when unauthenticated, redirects to sign in" do
    get root_path

    assert_redirected_to new_user_session_path
  end

  test "when authenticated, renders successfully" do
    sign_in users(:one)

    get root_path

    assert_response :success
  end

  test "with no avatar, shows a placeholder instead of an image in the composer" do
    sign_in users(:one)

    get root_path

    assert_select ".composer-avatar"
    assert_select ".composer-avatar img", count: 0
  end

  test "with no posts, shows the empty state" do
    sign_in users(:one)
    Post.destroy_all

    get root_path

    assert_select ".empty-state"
  end

  test "requesting a page past the last page shows the empty state" do
    sign_in users(:one)

    get root_path(page: 2)

    assert_response :success
    assert_select ".empty-state"
  end

  test "renders the feed with a bounded number of queries regardless of post count" do
    sign_in_and_absorb_trackable_update users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    assert_queries_count(10) { get root_path }

    create_post!(users(:one), description: "one more post")

    assert_queries_count(10) { get root_path }
  end

  test "shows the newest post first" do
    sign_in users(:one)
    newest = create_post!(users(:one), description: "the newest post")

    get root_path

    assert_select "section.post:first-of-type", text: /#{newest.description}/
  end

  test "shows no filled hearts for a user who has reacted to no posts" do
    sign_in users(:one)

    get root_path

    assert_select ".reaction-icon", count: 2
    assert_select ".reaction-icon.liked", count: 0
  end

  test "shows the filled heart only for posts the signed-in user has reacted to" do
    sign_in users(:two)

    get root_path

    assert_select ".reaction-icon", count: 2
    assert_select ".reaction-icon.liked", count: 1
  end

  test "shows a comment icon opening the post popup for each post" do
    sign_in users(:one)

    get root_path

    assert_select ".comment-icon", count: 2
    assert_select ".comment-icon[data-turbo-frame=?]", "post_modal", count: 2
  end

  test "shows each post's comment count" do
    sign_in users(:one)

    get root_path

    assert_select "##{dom_id(posts(:one), :comments_count)}", text: /1 comment/
    assert_select "##{dom_id(posts(:two), :comments_count)}", text: /1 comment/
  end

  test "when authenticated, paginates posts 10 per page" do
    sign_in users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path
    assert_select "section.post", count: 10
    assert_select "a[href=?]", root_path(page: 2)

    get root_path(page: 2)
    assert_select "section.post", count: Post.count - 10
  end

  test "with a non-numeric page param, renders the first page without erroring" do
    sign_in users(:one)

    get root_path(page: "not-a-number")

    assert_response :success
    assert_select "section.post", count: Post.count
  end

  private

  def sign_in_and_absorb_trackable_update(user)
    sign_in user
    get root_path
  end

  test "the feed sentinel links to the next page when more posts remain" do
    sign_in users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path

    assert_select "#feed_sentinel a[href=?]", root_path(page: 2)
  end

  test "the feed sentinel shows an end state on the last page" do
    sign_in users(:one)

    get root_path

    assert_select "#feed_sentinel a", false
    assert_select "#feed_sentinel", text: /caught up/i
  end

  test "a turbo navigation to the feed renders the full page rather than a bare stream" do
    sign_in users(:one)

    get root_path, headers: { "Accept" => TURBO_NAVIGATION_ACCEPT }

    assert_response :success
    assert_select "turbo-stream", false
    assert_select ".homepage"
  end

  test "requesting a page as turbo stream appends posts and replaces the sentinel" do
    sign_in users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path(page: 2), as: :turbo_stream

    assert_turbo_stream action: "append", target: "posts"
    assert_turbo_stream action: "replace", target: "feed_sentinel"
    assert_select "turbo-stream[action=append][target=posts] section.post", count: 3
  end
end
