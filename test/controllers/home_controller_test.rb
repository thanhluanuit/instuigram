require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
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

  test "when authenticated, paginates posts 10 per page" do
    sign_in users(:one)
    11.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path
    assert_select "section.post", count: 10

    get root_path(page: 2)
    assert_select "section.post", count: 3
  end
end
