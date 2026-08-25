require "test_helper"

class SidekiqWebTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, redirects to sign in" do
    get "/sidekiq"

    assert_redirected_to "/users/sign_in"
  end

  test "when authenticated as a non-admin user, is not found" do
    sign_in users(:one)

    get "/sidekiq"

    assert_response :not_found
  end

  test "when authenticated as an admin, renders successfully" do
    sign_in users(:admin)

    get "/sidekiq"

    assert_response :success
  end
end
