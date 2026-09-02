require "test_helper"

class Conversations::FindOrCreateTest < ActiveSupport::TestCase
  test "creates a conversation with both users as participants" do
    conversation = Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))

    assert conversation.persisted?
    assert_equal [ users(:admin), users(:two) ].sort_by(&:id), conversation.users.sort_by(&:id)
  end

  test "stores the sorted participants key" do
    conversation = Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))

    assert_equal Conversation.participants_key_for(users(:two), users(:admin)), conversation.participants_key
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

  test "returns the conversation that won the insert race rather than raising" do
    winner = Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))

    losing_the_insert_race do
      assert_equal winner, Conversations::FindOrCreate.call(user: users(:two), other_user: users(:admin))
    end
  end

  private

  def losing_the_insert_race
    raced = false
    inherited_find_by = Conversation.method(:find_by)

    Conversation.define_singleton_method(:find_by) do |*args|
      raced ? inherited_find_by.call(*args) : nil
    end

    Conversation.define_singleton_method(:create!) do |*|
      raced = true
      raise ActiveRecord::RecordNotUnique
    end

    yield
  ensure
    Conversation.singleton_class.remove_method(:find_by)
    Conversation.singleton_class.remove_method(:create!)
  end
end
