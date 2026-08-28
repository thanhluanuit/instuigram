require "test_helper"

class Follows::DestroyTest < ActiveSupport::TestCase
  setup do
    @follower = users(:one)
    @followed = users(:two)
  end

  test "destroys an existing follow" do
    Follows::Create.call(follower: @follower, followed: @followed)

    assert_difference("Follow.count", -1) { destroy_follow }
  end

  test "destroying decrements both counter caches" do
    Follows::Create.call(follower: @follower, followed: @followed)

    destroy_follow

    assert_equal 0, @followed.reload.followers_count
    assert_equal 0, @follower.reload.following_count
  end

  test "unfollowing someone you do not follow is a no-op" do
    assert_no_difference("Follow.count") { assert_nil destroy_follow }
  end

  private

  def destroy_follow(follower: @follower, followed: @followed)
    Follows::Destroy.call(follower: follower, followed: followed)
  end
end
