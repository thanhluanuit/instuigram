require 'test_helper'

class PostTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "is valid with a description, a user, and an attached image" do
    assert build_post.valid?
  end

  test "is valid without a description" do
    assert build_post(description: nil).valid?
  end

  test "is invalid without an attached image" do
    post = build_post(attach_image: false)

    assert_not post.valid?
    assert_includes post.errors[:image], "can't be blank"
  end

  test "is invalid without a user" do
    assert_not build_post(user: nil).valid?
  end

  test "with the :one fixture, belongs to the :one user" do
    assert_equal users(:one), posts(:one).user
  end

  test "with the :two fixture, belongs to the :two user" do
    assert_equal users(:two), posts(:two).user
  end

  test "with the :one fixture, has an attached image" do
    assert posts(:one).image.attached?
  end

  test "extracts every #word token from the description" do
    post = build_post(description: "loving this #sunset over the #beach today", attach_image: false)

    assert_equal %w[sunset beach], post.extract_name_hash_tags
  end

  test "extracts no tags from a description with none" do
    post = build_post(description: "just a plain caption", attach_image: false)

    assert_empty post.extract_name_hash_tags
  end

  test "creates a HashTag for each unique #word when saved" do
    post = build_post(description: "great #sunset at the #beach")

    assert_difference("HashTag.count", 2) { post.save! }
  end

  test "associates the saved post with the extracted hash tags" do
    post = build_post(description: "great #sunset at the #beach")
    post.save!

    assert_equal %w[beach sunset], post.hash_tags.pluck(:name).sort
  end

  test "creates no HashTag records when the description has no tags" do
    post = build_post(description: "no tags here")

    assert_no_difference("HashTag.count") { post.save! }
  end

  test "does not create additional hash tags when an existing post is updated" do
    post = build_post(description: "great #sunset")
    post.save!

    assert_no_difference("HashTag.count") { post.update!(description: "great #sunset and #mountains") }
  end

  private

  def build_post(user: @user, description: "hello world", attach_image: true)
    post = Post.new(user: user, description: description)
    if attach_image
      post.image.attach(
        io:           File.open(Rails.root.join("test/fixtures/files/test_image.png")),
        filename:     "test_image.png",
        content_type: "image/png"
      )
    end
    post
  end
end
