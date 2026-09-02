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

    assert_select "a.btn-outline[href=?]", edit_profile_path
  end

  test "paginates the post grid to 10 per page" do
    sign_in users(:one)
    10.times { |n| create_post!(users(:one), description: "post #{n}") }

    get profile_path

    assert_select ".thumbnail-grid .wrapper", 10
    assert_select ".pagination"
  end

  test "avoids N+1 queries when rendering multiple posts in the grid" do
    sign_in users(:one)
    create_post!(users(:one), description: "second post")

    assert_queries_count(11) { get profile_path }

    assert_response :success
  end

  test "edit, when unauthenticated, redirects to sign in" do
    get edit_profile_path

    assert_redirected_to new_user_session_path
  end

  test "edit omits the aside on the settings page so the form spans the full column" do
    sign_in users(:one)

    get edit_profile_path

    assert_select "nav.app-rail"
    assert_select "aside.app-shell__aside", false
  end

  test "edit links the settings sidebar to the change password page" do
    sign_in users(:one)

    get edit_profile_path

    assert_select "a[href=?]", edit_user_registration_path
  end

  test "update, when unauthenticated, redirects to sign in and does not update" do
    patch profile_path, params: { user: { name: "Hacked" } }

    assert_redirected_to new_user_session_path
    assert_not_equal "Hacked", users(:one).reload.name
  end

  test "update, when authenticated, updates current_user and redirects to their profile" do
    sign_in users(:one)

    patch profile_path, params: { user: { name: "New Name" } }

    assert_redirected_to profile_path
    assert_equal "New Name", users(:one).reload.name
  end

  test "update, when authenticated with valid params, logs a profile_updated event" do
    sign_in users(:one)

    assert_difference("EventLog.count", 1) do
      perform_enqueued_jobs { patch profile_path, params: { user: { name: "New Name" } } }
    end

    event_log = EventLog.last
    assert_equal "profile_updated", event_log.event_type
    assert_equal users(:one), event_log.subject
    assert_equal users(:one), event_log.user
  end

  test "update, when authenticated with an invalid email, does not persist the change" do
    sign_in users(:one)

    assert_no_difference("EventLog.count") do
      patch profile_path, params: { user: { email: "not-an-email" } }
    end

    assert_not_equal "not-an-email", users(:one).reload.email
  end
end
