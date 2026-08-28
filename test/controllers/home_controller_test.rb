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

  test "with no avatar, shows the fallback icon in the composer" do
    sign_in users(:one)

    get root_path

    assert_select ".composer-avatar i.fa-user"
  end

  test "with no posts, shows the empty state" do
    sign_in users(:one)
    Post.destroy_all

    get root_path

    assert_select ".empty-state"
    assert_select "section.post", count: 0
  end

  test "requesting a page past the last page shows the empty state" do
    sign_in users(:one)

    get root_path(page: 2)

    assert_response :success
    assert_select ".empty-state"
  end

  test "renders the feed with a bounded number of queries regardless of post count" do
    sign_in users(:one)
    get root_path

    11.times { |n| create_post!(users(:one), description: "post #{n}") }
    assert_queries_count(10) { get root_path }

    10.times { |n| create_post!(users(:one), description: "later post #{n}") }
    assert_queries_count(10) { get root_path }
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
    assert_select "nav.pagination"

    get root_path(page: 2)
    assert_select "section.post", count: 3
  end

  test "with a non-numeric page param, falls back to the first page" do
    sign_in users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path(page: "not-a-number")

    assert_response :success
    assert_select "section.post", count: 10
  end
end
