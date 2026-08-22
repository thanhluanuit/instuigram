require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "is visible to an anonymous visitor" do
    get user_path(users(:one))

    assert_response :success
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

  test "when signed in as the profile owner, shows an Edit Profile link" do
    sign_in users(:one)

    get user_path(users(:one))

    assert_select "a.edit-profile"
  end

  test "when signed in as a different user, hides the Edit Profile link" do
    sign_in users(:two)

    get user_path(users(:one))

    assert_select "a.edit-profile", count: 0
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
      patch user_path(users(:one)), params: { user: { name: "New Name" } }
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
end
