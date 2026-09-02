require "application_system_test_case"

class InboxTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    visit conversations_path
    wait_for_page_to_settle
    wait_for_cable("inbox")
  end

  test "a message from another user raises the unread badge without a page reload" do
    assert_selector "#unread-badge", text: "1"

    assert_no_navigation do
      send_admin_message

      assert_selector "#unread-badge", text: "2"
    end
  end

  test "a message from another user rewrites its inbox row and moves it to the top" do
    assert_selector ".conversations__list > .conversation-row:nth-child(1)##{dom_id(conversations(:one_and_two))}"
    assert_selector ".conversations__list > .conversation-row:nth-child(2)##{dom_id(conversations(:one_and_admin))}"

    assert_no_navigation do
      send_admin_message

      within "##{dom_id(conversations(:one_and_admin))}" do
        assert_selector ".conversation-row__sender", text: "#{users(:admin).username}:"
        assert_selector ".conversation-row__text", text: "Standup in five"
        assert_selector ".conversation-row__unread", text: "2"
      end

      assert_selector ".conversations__list > .conversation-row:nth-child(1)##{dom_id(conversations(:one_and_admin))}"
      assert_selector ".conversations__list > .conversation-row:nth-child(2)##{dom_id(conversations(:one_and_two))}"
    end
  end

  private

  def send_admin_message
    within_session_as(:admin, users(:admin)) do
      visit conversation_path(conversations(:one_and_admin))
      fill_in "message_body", with: "Standup in five"
      click_button "Send"

      assert_selector ".chat-message--mine", text: "Standup in five"
    end
  end
end
