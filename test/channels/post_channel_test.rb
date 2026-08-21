require "test_helper"

class PostChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams for the post when given a valid post id" do
    subscribe(id: posts(:one).id)

    assert subscription.confirmed?
    assert_has_stream_for posts(:one)
  end

  test "rejects the subscription when the post id does not exist" do
    subscribe(id: -1)

    assert subscription.rejected?
  end
end
