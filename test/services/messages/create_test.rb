require "test_helper"

class Messages::CreateTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:one_and_two)
  end

  test "creates a message owned by the sender" do
    message = send_message("hello")

    assert message.persisted?
    assert_equal users(:one), message.user
    assert_equal @conversation, message.conversation
  end

  test "points the conversation at the newly created message" do
    message = send_message("hello")

    assert_equal message, @conversation.reload.last_message
    assert_equal message.created_at, @conversation.last_message_at
  end

  test "increments the unread count of the other participant" do
    send_message("hello")

    assert_equal 4, @conversation.participant_for(users(:two)).reload.unread_count
  end

  test "clears the sender's own unread count" do
    participant = @conversation.participant_for(users(:one))
    participant.update!(unread_count: 5)

    send_message("hello")

    assert_equal 0, participant.reload.unread_count
  end

  test "when the body is blank, persists nothing and leaves unread counts untouched" do
    assert_no_difference("Message.count") do
      message = send_message("   ")

      assert_not message.persisted?
    end

    assert_equal 3, @conversation.participant_for(users(:two)).reload.unread_count
  end

  test "broadcasts the message exactly once regardless of participant count" do
    assert_broadcasts(ConversationChannel.broadcasting_for(@conversation), 1) do
      send_message("hello")
    end
  end

  test "the broadcast carries the rendered message markup" do
    message = nil

    broadcast = capture_broadcasts(ConversationChannel.broadcasting_for(@conversation)) do
      message = send_message("hello")
    end.first

    assert_includes broadcast, ActionView::RecordIdentifier.dom_id(message)
    assert_includes broadcast, "hello"
  end

  test "broadcasts an inbox update to each participant" do
    assert_broadcasts(InboxChannel.broadcasting_for(users(:two)), 1) do
      assert_broadcasts(InboxChannel.broadcasting_for(users(:one)), 1) do
        send_message("hello")
      end
    end
  end

  test "the inbox broadcast carries the recipient's own unread total" do
    payload = capture_broadcasts(InboxChannel.broadcasting_for(users(:two))) do
      send_message("hello")
    end.first

    assert_equal 4, payload["unread_count"]
    assert_equal 4, payload["total_unread"]
    assert_equal "hello", payload["preview"]
  end

  test "the inbox broadcast tells the sender their own count is cleared" do
    payload = capture_broadcasts(InboxChannel.broadcasting_for(users(:one))) do
      send_message("hello")
    end.first

    assert_equal 0, payload["unread_count"]
    assert_equal 1, payload["total_unread"]
  end

  test "broadcasts nothing when the body is blank" do
    assert_no_broadcasts(ConversationChannel.broadcasting_for(@conversation)) do
      send_message("   ")
    end
  end

  test "when the body is blank, leaves the conversation's last message alone" do
    send_message("   ")

    assert_equal messages(:latest_from_one), @conversation.reload.last_message
  end

  private

  def send_message(body = "hello", user: users(:one))
    Messages::Create.call(conversation: @conversation, user: user, body: body)
  end
end
