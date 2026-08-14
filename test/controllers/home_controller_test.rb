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

  test "when authenticated, shows at most 5 posts on the first page" do
    sign_in users(:one)
    6.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path

    assert_select "section.post", count: 5
  end

  test "when authenticated, shows the remaining posts on the second page" do
    sign_in users(:one)
    6.times { |n| create_post!(users(:one), description: "post #{n}") }

    get root_path(page: 2)

    assert_select "section.post", count: 3
  end

  private

  def create_post!(user, description:)
    post = user.posts.new(description: description)
    post.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
      filename: "test_image.png",
      content_type: "image/png"
    )
    post.save!
    post
  end
end
