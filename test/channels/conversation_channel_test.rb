require "test_helper"

class ConversationChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams for the conversation when the user is a participant" do
    stub_connection(current_user: users(:one))
    subscribe(id: conversations(:one_and_two).id)

    assert subscription.confirmed?
    assert_has_stream_for conversations(:one_and_two)
  end

  test "rejects the subscription when the user is not a participant" do
    stub_connection(current_user: users(:admin))
    subscribe(id: conversations(:one_and_two).id)

    assert subscription.rejected?
  end

  test "rejects the subscription when the connection is anonymous" do
    stub_connection(current_user: nil)
    subscribe(id: conversations(:one_and_two).id)

    assert subscription.rejected?
  end

  test "rejects the subscription when the conversation does not exist" do
    stub_connection(current_user: users(:one))
    subscribe(id: -1)

    assert subscription.rejected?
  end
end
