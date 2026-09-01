require "test_helper"

class ExploreControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "when unauthenticated, redirects to sign in" do
    get explore_path

    assert_redirected_to new_user_session_path
  end

  test "omits the signed-in user's own posts from the grid" do
    sign_in @user

    get explore_path

    assert_select "a[href=?]", post_path(posts(:one)), count: 0
    assert_select "a[href=?]", post_path(posts(:two))
  end

  test "omits posts by people the signed-in user already follows" do
    @user.following_relationships.create!(followed: users(:two))
    sign_in @user

    get explore_path

    assert_select "a[href=?]", post_path(posts(:two)), count: 0
  end

  test "renders the aside with trending hashtags" do
    sign_in @user

    get explore_path

    assert_select "aside.app-shell__aside .aside-hashtags" do
      assert_select "a[href=?]", search_path(query: "##{hash_tags(:one).name}")
    end
  end

  test "paginates the grid to 12 per page" do
    12.times { |n| create_post!(users(:two), description: "post #{n}") }
    sign_in @user

    get explore_path
    assert_select ".thumbnail-grid .wrapper", count: 12

    get explore_path(page: 2)
    assert_select ".thumbnail-grid .wrapper", count: 1
  end

  test "when the user follows everyone with posts, shows the Explore empty state" do
    @user.following_relationships.create!(followed: users(:two))
    sign_in @user

    get explore_path

    assert_select ".empty-state p", /already following everyone/
  end

  test "avoids N+1 queries when rendering multiple posts in the grid" do
    create_post!(users(:two), description: "second discoverable post")
    sign_in @user

    assert_queries_count(12) { get explore_path }

    assert_select ".thumbnail-grid .wrapper", count: 2
  end
end
