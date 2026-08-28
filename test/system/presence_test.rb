require "application_system_test_case"

class PresenceTest < ApplicationSystemTestCase
  test "when the other participant comes online, the conversation header shows them as active" do
    sign_in_as users(:one)
    visit conversation_path(conversations(:one_and_two))
    wait_for_page_to_settle
    wait_for_cable("presence")

    assert_selector "[data-presence-status-for='#{users(:two).id}']", text: "Offline"

    within_session_as(:two, users(:two)) do
      wait_for_cable("presence")
    end

    assert_selector "[data-presence-status-for='#{users(:two).id}']", text: "Active now"
    assert_selector ".presence-dot.is-online[data-presence-user-id='#{users(:two).id}']"
  end
end
