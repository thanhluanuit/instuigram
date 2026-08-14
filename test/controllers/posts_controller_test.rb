require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, redirects to sign in and creates no post" do
    assert_no_difference("Post.count") { post posts_path, params: valid_post_params }

    assert_redirected_to new_user_session_path
  end

  test "when authenticated with valid params, creates a post owned by current_user and redirects home" do
    sign_in users(:one)

    assert_difference("Post.count", 1) do
      post posts_path, params: valid_post_params(description: "hello #world")
    end

    assert_equal users(:one), Post.last.user
    assert_redirected_to root_path
  end

  test "when authenticated, ignores a client-supplied user_id and attributes the post to current_user" do
    sign_in users(:one)

    post posts_path, params: {
      post: {
        description: "sneaky",
        user_id: users(:two).id,
        image: fixture_file_upload("test_image.png", "image/png")
      }
    }

    assert_equal users(:one), Post.last.user
  end

  test "when authenticated without an image, creates no post" do
    sign_in users(:one)

    assert_no_difference("Post.count") do
      post posts_path, params: { post: { description: "no image attached" } }
    end
  end

  test "is visible to an anonymous visitor" do
    get post_path(posts(:one))

    assert_response :success
  end

  test "when signed in as the post's owner, shows a Remove link" do
    sign_in users(:one)

    get post_path(posts(:one))

    assert_select "a", "Remove"
  end

  test "when signed in as a different user, hides the Remove link" do
    sign_in users(:two)

    get post_path(posts(:one))

    assert_select "a", { text: "Remove", count: 0 }
  end

  test "when unauthenticated, redirects to sign in and does not delete the post" do
    assert_no_difference("Post.count") { delete post_path(posts(:one)) }

    assert_redirected_to new_user_session_path
  end

  test "when signed in as the post's owner, deletes the post and redirects to their profile" do
    sign_in users(:one)

    assert_difference("Post.count", -1) { delete post_path(posts(:one)) }

    assert_redirected_to user_path(users(:one))
  end

  test "when signed in as a different user, responds not found and does not delete the post" do
    sign_in users(:two)

    delete post_path(posts(:one))

    assert_response :not_found
    assert Post.exists?(posts(:one).id)
  end

  private

  def valid_post_params(description: "a caption")
    {
      post: {
        description: description,
        image: fixture_file_upload("test_image.png", "image/png")
      }
    }
  end
end
