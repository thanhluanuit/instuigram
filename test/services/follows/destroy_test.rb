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

  test "broadcasts a count refresh to both users' profile streams" do
    Follows::Create.call(follower: @follower, followed: @followed)

    assert_enqueued_jobs 2, only: Turbo::Streams::ActionBroadcastJob do
      destroy_follow
    end
  end

  test "unfollowing someone you do not follow broadcasts nothing" do
    assert_no_enqueued_jobs(only: Turbo::Streams::ActionBroadcastJob) { destroy_follow }
  end

  test "broadcasts the follow button back to the follower's own stream" do
    Follows::Create.call(follower: @follower, followed: @followed)

    broadcast = capture_broadcasts(follow_state_stream(@follower)) { destroy_follow }.first

    assert_includes broadcast, "Follow #{@followed.username}"
  end

  test "unfollowing someone you do not follow broadcasts no button" do
    assert_no_broadcasts(follow_state_stream(@follower)) { destroy_follow }
  end

  private

  def destroy_follow(follower: @follower, followed: @followed)
    Follows::Destroy.call(follower: follower, followed: followed)
  end
end
