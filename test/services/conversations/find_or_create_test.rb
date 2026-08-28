require "test_helper"

class Conversations::FindOrCreateTest < ActiveSupport::TestCase
  test "creates a conversation with both users as participants" do
    conversation = Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))

    assert conversation.persisted?
    assert_equal [ users(:admin), users(:two) ].sort_by(&:id), conversation.users.sort_by(&:id)
  end

  test "stores the sorted participants key" do
    conversation = Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))

    assert_equal Conversation.key_for(users(:two), users(:admin)), conversation.participants_key
  end

  test "returns the existing conversation instead of creating a second one" do
    assert_no_difference("Conversation.count") do
      conversation = Conversations::FindOrCreate.call(user: users(:one), other_user: users(:two))

      assert_equal conversations(:one_and_two), conversation
    end
  end

  test "finds the same conversation regardless of which user initiates" do
    first  = Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))
    second = Conversations::FindOrCreate.call(user: users(:admin), other_user: users(:two))

    assert_equal first, second
  end

  test "returns nil when a user tries to message themselves" do
    assert_no_difference("Conversation.count") do
      assert_nil Conversations::FindOrCreate.call(user: users(:one), other_user: users(:one))
    end
  end
end
