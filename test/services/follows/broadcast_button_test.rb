require "test_helper"

class Follows::BroadcastButtonTest < ActiveSupport::TestCase
  setup do
    @follower = users(:one)
    @followed = users(:two)
  end

  test "broadcasts a replace targeting every follow button for the followed user" do
    broadcast = capture_broadcasts(follow_state_stream(@follower)) do
      broadcast_button(following: true)
    end.first

    assert_includes broadcast, %(action="replace")
    assert_includes broadcast, %(targets="[data-follow-user-id=&#39;#{@followed.id}&#39;]")
  end

  test "broadcasts the following state when the follow was created" do
    broadcast = capture_broadcasts(follow_state_stream(@follower)) do
      broadcast_button(following: true)
    end.first

    assert_includes broadcast, "Following"
    assert_includes broadcast, "Unfollow #{@followed.username}"
  end

  test "broadcasts the follow state when the follow was destroyed" do
    broadcast = capture_broadcasts(follow_state_stream(@follower)) do
      broadcast_button(following: false)
    end.first

    assert_includes broadcast, "Follow #{@followed.username}"
    assert_not_includes broadcast, "Unfollow"
  end

  test "broadcasts nothing to the followed user's own stream" do
    assert_no_broadcasts(follow_state_stream(@followed)) do
      broadcast_button(following: true)
    end
  end

  private

  def broadcast_button(following:)
    Follows::BroadcastButton.call(follower: @follower, followed: @followed, following: following)
  end
end
