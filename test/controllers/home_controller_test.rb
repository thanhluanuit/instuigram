require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  test "when unauthenticated, redirects to sign in" do
    get root_path

    assert_redirected_to new_user_session_path
  end

  test "when authenticated, renders successfully" do
    sign_in users(:one)

    get root_path

    assert_response :success
  end

  test "renders the feed with a bounded number of queries regardless of post count" do
    sign_in users(:one)

    assert_queries_count(11) { get root_path }
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

    get root_path(page: 2)
    assert_select "section.post", count: 3
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

  test "requesting a page as turbo stream appends posts and replaces the sentinel" do
    sign_in users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path(page: 2), as: :turbo_stream

    assert_turbo_stream action: "append", target: "posts"
    assert_turbo_stream action: "replace", target: "feed_sentinel"
    assert_select "turbo-stream[action=append][target=posts] section.post", count: 3
  end
end
