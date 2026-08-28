require "test_helper"

class Conversations::ReadsControllerTest < ActionDispatch::IntegrationTest
  test "marking a conversation read clears the viewer's unread count" do
    sign_in users(:two)

    post conversation_read_path(conversations(:one_and_two))

    assert_response :no_content
    assert_equal 0, conversations(:one_and_two).participant_for(users(:two)).reload.unread_count
  end

  test "when not a participant, responds not found" do
    sign_in users(:admin)

    post conversation_read_path(conversations(:one_and_two))

    assert_response :not_found
  end
end
