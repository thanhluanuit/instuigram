require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, redirects to sign in" do
    get profile_path

    assert_redirected_to new_user_session_path
  end

  test "renders the navigation rail with Profile marked current" do
    sign_in users(:one)

    get profile_path

    assert_select "nav.app-rail"
    assert_select "nav.app-rail a.is-active[aria-current=?]", "page", text: /Profile/
  end

  test "shows an Edit Profile link" do
    sign_in users(:one)

    get profile_path

    assert_select "a.btn-outline[href=?]", edit_user_path(users(:one))
  end

  test "paginates the post grid to 10 per page" do
    sign_in users(:one)
    10.times { |n| create_post!(users(:one), description: "post #{n}") }

    get profile_path

    assert_select ".thumbnail-grid .wrapper", 10
    assert_select ".pagination"
  end
end
