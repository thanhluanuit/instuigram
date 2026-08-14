require 'test_helper'

class HashTagTest < ActiveSupport::TestCase
  test "is valid with a name" do
    assert HashTag.new(name: "sunset").valid?
  end

  test "has many posts through the :one fixture" do
    assert_equal [posts(:one)], hash_tags(:one).posts
  end

  test "destroying a hash_tag does not destroy its post_hash_tags" do
    hash_tag = hash_tags(:one)

    assert_no_difference("PostHashTag.count") { hash_tag.destroy }
  end
end
