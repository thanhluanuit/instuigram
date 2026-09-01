require "test_helper"

class User::AvatarableTest < ActiveSupport::TestCase
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
end
