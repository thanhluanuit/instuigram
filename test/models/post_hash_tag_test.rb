require "test_helper"

class PostHashTagTest < ActiveSupport::TestCase
  test "is valid with a post and a hash_tag" do
    assert PostHashTag.new(post: posts(:one), hash_tag: hash_tags(:one)).valid?
  end

  test "is invalid without a post" do
    assert_not PostHashTag.new(hash_tag: hash_tags(:one)).valid?
  end

  test "is invalid without a hash_tag" do
    assert_not PostHashTag.new(post: posts(:one)).valid?
  end

  test "belongs to a post via the :one fixture" do
    assert_equal posts(:one), post_hash_tags(:one).post
  end

  test "belongs to a hash_tag via the :one fixture" do
    assert_equal hash_tags(:one), post_hash_tags(:one).hash_tag
  end
end
