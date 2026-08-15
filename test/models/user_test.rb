require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with an email and a password" do
    assert build_user.valid?
  end

  test "is invalid without an email" do
    assert_not build_user(email: nil).valid?
  end

  test "is invalid with a duplicate email" do
    assert_not build_user(email: users(:one).email).valid?
  end

  test "is invalid without a password" do
    assert_not build_user(password: nil).valid?
  end

  test "is invalid with a password shorter than the minimum length" do
    assert_not build_user(password: "12345").valid?
  end

  test "is invalid with a javascript: URI as website" do
    assert_not build_user(website: "javascript:alert(document.cookie)").valid?
  end

  test "is valid with an http(s) website" do
    assert build_user(website: "https://example.com").valid?
  end

  test "can have an attached avatar" do
    user = build_user
    attach_test_image(user.avatar)

    assert user.avatar.attached?
  end

  test "is invalid with a non-image avatar" do
    user = build_user
    attach_non_image_file(user.avatar)

    assert_not user.valid?
    assert_includes user.errors[:avatar], "must be a PNG, JPEG, or WebP"
  end

  test "is invalid with an avatar over the size limit" do
    user = build_user
    attach_oversized_image(user.avatar)

    assert_not user.valid?
    assert_includes user.errors[:avatar], "must be smaller than 10MB"
  end

  test "has many posts through the :one fixture" do
    assert_equal [ posts(:one) ], users(:one).posts
  end

  test "destroying a user destroys their posts" do
    user = users(:one)
    post_id = posts(:one).id

    assert_difference("Post.count", -1) { user.destroy }
    assert_not Post.exists?(post_id)
  end

  private

  def build_user(email: "new_user@example.com", password: "password123", username: "new_user", website: nil)
    User.new(email: email, password: password, username: username, website: website)
  end
end
