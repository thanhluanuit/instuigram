require "test_helper"

class Post::ImageableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "is invalid without an attached image" do
    post = build_post(@user, attach_image: false)

    assert_not post.valid?
    assert_includes post.errors[:image], "can't be blank"
  end

  test "is invalid with a non-image attachment" do
    post = build_post(@user, attach_image: false)
    attach_non_image_file(post.image)

    assert_not post.valid?
    assert_includes post.errors[:image], "must be a PNG, JPEG, or WebP"
  end

  test "is invalid with an image over the size limit" do
    post = build_post(@user, attach_image: false)
    attach_oversized_image(post.image)

    assert_not post.valid?
    assert_includes post.errors[:image], "must be smaller than 10MB"
  end

  test "with the :one fixture, has an attached image" do
    assert posts(:one).image.attached?
  end
end
