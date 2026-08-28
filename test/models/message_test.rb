require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "chronological orders messages oldest first" do
    assert_equal [ messages(:from_one), messages(:from_two), messages(:latest_from_one) ],
                 conversations(:one_and_two).messages.chronological.to_a
  end

  test "is invalid without a body" do
    message = Message.new(conversation: conversations(:one_and_two), user: users(:one), body: "  ")

    assert_not message.valid?
  end

  test "is invalid when the body exceeds 1000 characters" do
    message = Message.new(conversation: conversations(:one_and_two), user: users(:one), body: "a" * 1001)

    assert_not message.valid?
  end
end
