require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "participants_key_for builds the same key regardless of argument order" do
    assert_equal Conversation.participants_key_for(users(:one), users(:two)),
                 Conversation.participants_key_for(users(:two), users(:one))
  end

  test "participants_key_for joins the participant ids in ascending order" do
    expected = [ users(:one).id, users(:two).id ].sort.join("-")

    assert_equal expected, Conversation.participants_key_for(users(:one), users(:two))
  end

  test "other_participant returns the participant who is not the viewer" do
    assert_equal users(:two), conversations(:one_and_two).other_participant(users(:one))
  end

  test "participant_for returns the viewer's own participant row" do
    assert_equal conversation_participants(:one_in_one_and_two),
                 conversations(:one_and_two).participant_for(users(:one))
  end

  test "ordered sorts conversations by most recent message first" do
    assert_equal [ conversations(:one_and_two), conversations(:one_and_admin) ],
                 Conversation.ordered.to_a
  end

  test "the database rejects a second conversation with the same participants key" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Conversation.create!(participants_key: conversations(:one_and_two).participants_key)
    end
  end

  test "destroying a conversation destroys its messages and participants" do
    conversation = conversations(:one_and_two)

    assert_difference("Message.count", -3) do
      assert_difference("ConversationParticipant.count", -2) do
        conversation.destroy
      end
    end
  end
end
