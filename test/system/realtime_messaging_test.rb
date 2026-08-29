require "application_system_test_case"

class RealtimeMessagingTest < ApplicationSystemTestCase
  test "a message from the other participant appears in an open conversation without a reload" do
    sign_in_as users(:one)
    visit conversation_path(conversations(:one_and_two))
    wait_for_page_to_settle
    assert_selector ".chat-message", count: 3
    wait_for_cable("conversation")

    assert_no_navigation do
      within_session_as(:two, users(:two)) do
        visit conversation_path(conversations(:one_and_two))
        fill_in "message_body", with: "Are you around?"
        click_button "Send"

        assert_selector ".chat-message--mine", text: "Are you around?"
      end

      assert_selector ".chat-message", count: 4
      assert_selector ".chat-message", text: "Are you around?"
      assert_no_selector ".chat-message--mine", text: "Are you around?"
    end
  end
end
