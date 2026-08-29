require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "is visible to an anonymous visitor" do
    get user_path(users(:one))

    assert_response :success
  end

  test "renders the navigation rail for a signed in visitor, with Profile marked current" do
    sign_in users(:one)

    get user_path(users(:one))

    assert_select "nav.app-rail"
    assert_select "nav.app-rail a.is-active[aria-current=?]", "page", text: /Profile/
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

  test "renders the aside on the settings page" do
    sign_in users(:one)

    get edit_user_path(users(:one))

    assert_select "aside.app-shell__aside .aside-account__name", text: users(:one).username
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

  test "when signed in as the profile owner, shows an Edit Profile link" do
    sign_in users(:one)

    get user_path(users(:one))

    assert_select "a.btn-outline[href=?]", edit_user_path(users(:one))
  end

  test "when signed in as a different user, hides the Edit Profile link" do
    sign_in users(:two)

    get user_path(users(:one))

    assert_select "a.btn-outline[href=?]", edit_user_path(users(:one)), count: 0
  end

  test "edit, when unauthenticated, redirects to sign in" do
    get edit_user_path(users(:one))

    assert_redirected_to new_user_session_path
  end

  test "edit, when authenticated, renders successfully regardless of the url's user id" do
    sign_in users(:one)

    get edit_user_path(users(:two))

    assert_response :success
  end

  test "update, when unauthenticated, redirects to sign in and does not update" do
    patch user_path(users(:one)), params: { user: { name: "Hacked" } }

    assert_redirected_to new_user_session_path
    assert_not_equal "Hacked", users(:one).reload.name
  end

  test "update, when authenticated, updates current_user and redirects to their profile" do
    sign_in users(:one)

    patch user_path(users(:one)), params: { user: { name: "New Name" } }

    assert_redirected_to user_path(users(:one))
    assert_equal "New Name", users(:one).reload.name
  end

  test "update, when authenticated with valid params, logs a profile_updated event" do
    sign_in users(:one)

    assert_difference("EventLog.count", 1) do
      perform_enqueued_jobs { patch user_path(users(:one)), params: { user: { name: "New Name" } } }
    end

    event_log = EventLog.last
    assert_equal "profile_updated", event_log.event_type
    assert_equal users(:one), event_log.subject
    assert_equal users(:one), event_log.user
  end

  test "update, when authenticated, ignores the url's user id and only ever updates current_user" do
    sign_in users(:one)

    patch user_path(users(:two)), params: { user: { name: "Sneaky" } }

    assert_equal "Sneaky", users(:one).reload.name
    assert_not_equal "Sneaky", users(:two).reload.name
  end

  test "update, when authenticated with an invalid email, does not persist the change" do
    sign_in users(:one)

    assert_no_difference("EventLog.count") do
      patch user_path(users(:one)), params: { user: { email: "not-an-email" } }
    end

    assert_not_equal "not-an-email", users(:one).reload.email
  end

  test "edit, when authenticated, links the settings sidebar to the change password page" do
    sign_in users(:one)

    get edit_user_path(users(:one))

    assert_select "a[href=?]", edit_user_registration_path
  end
end
