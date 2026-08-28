require "application_system_test_case"

class ChatsTest < ApplicationSystemTestCase
  test "messaging another user from their profile shows the message in the conversation" do
    sign_in_as users(:one)

    visit user_path(users(:two))
    click_button "Message"

    fill_in "message_body", with: "Hello from the system test"
    click_button "Send"

    assert_text "Hello from the system test"
  end

  test "opening a conversation from the inbox clears the unread badge" do
    sign_in_as users(:two)

    assert_selector "#unread-badge", text: "3"

    visit conversations_path
    find("#conversation_#{conversations(:one_and_two).id}").click

    assert_current_path conversation_path(conversations(:one_and_two))
    assert_no_selector "#unread-badge", text: "3"
  end
end
