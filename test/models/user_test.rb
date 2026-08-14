require 'test_helper'

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

  test "can have an attached avatar" do
    user = build_user
    user.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
      filename: "test_image.png",
      content_type: "image/png"
    )

    assert user.avatar.attached?
  end

  test "has many posts through the :one fixture" do
    assert_equal [posts(:one)], users(:one).posts
  end

  test "destroying a user destroys their posts" do
    user = users(:one)
    post_id = posts(:one).id

    assert_difference("Post.count", -1) { user.destroy }
    assert_not Post.exists?(post_id)
  end

  private

  def build_user(email: "new_user@example.com", password: "password123", username: "new_user")
    User.new(email: email, password: password, username: username)
  end
end
