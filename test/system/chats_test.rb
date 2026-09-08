require "application_system_test_case"

class ChatsTest < ApplicationSystemTestCase
  test "sending a message shows it in the conversation" do
    sign_in_as users(:one)

    visit conversation_path(conversations(:one_and_two))
    assert_selector ".chat-message--mine"

    fill_in "message_body", with: "Hello from the system test"
    click_button "Send"

    assert_selector ".chat-message--mine", text: "Hello from the system test"
    assert_current_path conversation_path(conversations(:one_and_two))
  end

  test "the message button on a profile opens a conversation with that user" do
    sign_in_as users(:one)

    visit user_path(users(:two))
    click_button "Message"

    assert_current_path conversation_path(conversations(:one_and_two))
  end
end
