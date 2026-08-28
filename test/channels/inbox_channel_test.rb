require "test_helper"

class InboxChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams for the signed-in user" do
    stub_connection(current_user: users(:one))
    subscribe

    assert subscription.confirmed?
    assert_has_stream_for users(:one)
  end

  test "rejects the subscription when the connection is anonymous" do
    stub_connection(current_user: nil)
    subscribe

    assert subscription.rejected?
  end

  test "does not stream for another user" do
    stub_connection(current_user: users(:one))
    subscribe

    assert_has_no_stream_for users(:two)
  end
end
