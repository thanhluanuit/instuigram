require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "is visible to an anonymous visitor" do
    get user_path(users(:one))

    assert_response :success
  end

  test "renders the navigation rail for a signed in visitor" do
    sign_in users(:two)

    get user_path(users(:one))

    assert_select "nav.app-rail"
  end

  test "when signed in as the profile owner, redirects to the canonical profile path" do
    sign_in users(:one)

    get user_path(users(:one))

    assert_redirected_to profile_path
  end

  test "omits the navigation rail for an anonymous visitor" do
    get user_path(users(:one))

    assert_select "nav.app-rail", false
  end

  test "renders the aside with a profile summary for a signed in visitor" do
    users(:one).update!(bio: "Baking bread and chasing light.")
    sign_in users(:two)

    get user_path(users(:one))

    assert_select "aside.app-shell__aside .aside-profile" do
      assert_select ".aside-account__name", text: users(:one).username
      assert_select ".aside-profile__bio", text: "Baking bread and chasing light."
    end
  end

  test "omits the aside for an anonymous visitor" do
    get user_path(users(:one))

    assert_select "aside.app-shell__aside", false
  end

  test "shows the bio when the profile has one" do
    users(:one).update!(bio: "Baking bread and chasing light.")

    get user_path(users(:one))

    assert_select ".profile-header__bio", text: "Baking bread and chasing light."
  end

  test "omits the bio element when the profile has none" do
    users(:one).update!(bio: nil)

    get user_path(users(:one))

    assert_select ".profile-header__bio", false
  end

  test "falls back to the monogram when the profile has no avatar" do
    users(:one).avatar.purge

    get user_path(users(:one))

    assert_select ".profile-header__avatar .avatar-monogram"
  end

  test "responds not found for a nonexistent user" do
    get user_path(id: -1)

    assert_response :not_found
  end

  test "avoids N+1 queries when rendering multiple posts in the grid" do
    create_post!(users(:one), description: "second post")

    assert_queries_count(6) { get user_path(users(:one)) }

    assert_response :success
  end

  test "paginates the post grid to 10 per page" do
    10.times { |n| create_post!(users(:one), description: "post #{n}") }

    get user_path(users(:one))

    assert_select ".thumbnail-grid .wrapper", 10
    assert_select ".pagination"
  end

  test "when signed in as a different user, hides the Edit Profile link" do
    sign_in users(:two)

    get user_path(users(:one))

    assert_select "a.btn-outline[href=?]", edit_profile_path, count: 0
  end

  test "no longer routes profile settings under a user id" do
    sign_in users(:one)

    get "/users/#{users(:two).id}/edit"
    assert_response :not_found

    patch "/users/#{users(:two).id}", params: { user: { name: "Sneaky" } }
    assert_response :not_found
    assert_not_equal "Sneaky", users(:one).reload.name
  end
end
