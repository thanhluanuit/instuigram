require 'test_helper'

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

  test "when authenticated, paginates posts 5 per page" do
    sign_in users(:one)
    6.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path
    assert_select "section.post", count: 5

    get root_path(page: 2)
    assert_select "section.post", count: 3
  end

  private

  def create_post!(user, description:)
    post = user.posts.new(description: description)
    attach_test_image(post.image)
    post.save!
    post
  end
end
