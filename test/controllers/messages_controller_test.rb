require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, creates no message" do
    assert_no_difference("Message.count") do
      post conversation_messages_path(conversations(:one_and_two)), params: { message: { body: "hi" } }
    end

    assert_redirected_to new_user_session_path
  end

  test "a participant can send a message and it is logged" do
    sign_in users(:one)

    assert_difference([ "Message.count", "EventLog.count" ], 1) do
      perform_enqueued_jobs do
        post conversation_messages_path(conversations(:one_and_two)), params: { message: { body: "hi" } }
      end
    end

    assert_equal "message_sent", EventLog.last.event_type
  end

  test "the sender receives the new message without relying on the broadcast" do
    sign_in users(:one)

    post conversation_messages_path(conversations(:one_and_two)),
         params: { message: { body: "hi" } },
         as: :turbo_stream

    assert_response :success
    assert_includes response.body, ActionView::RecordIdentifier.dom_id(Message.last)
    assert_includes response.body, "hi"
  end

  test "when not a participant, responds not found and creates no message" do
    sign_in users(:admin)

    assert_no_difference("Message.count") do
      post conversation_messages_path(conversations(:one_and_two)), params: { message: { body: "hi" } }
    end

    assert_response :not_found
  end

  test "a blank body creates no message" do
    sign_in users(:one)

    assert_no_difference("Message.count") do
      post conversation_messages_path(conversations(:one_and_two)), params: { message: { body: "  " } }
    end

    assert_redirected_to conversation_path(conversations(:one_and_two))
  end
end
