require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, redirects the inbox to sign in" do
    get conversations_path

    assert_redirected_to new_user_session_path
  end

  test "when unauthenticated, creates no conversation" do
    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:two).id }
    end

    assert_redirected_to new_user_session_path
  end

  test "lists only the signed-in user's conversations" do
    sign_in users(:two)

    get conversations_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(conversations(:one_and_two))}"
    assert_select "##{ActionView::RecordIdentifier.dom_id(conversations(:one_and_admin))}", false
  end

  test "renders a conversation the user participates in" do
    sign_in users(:one)

    get conversation_path(conversations(:one_and_two))

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(messages(:from_one))}"
  end

  test "when not a participant, responds not found" do
    sign_in users(:admin)

    get conversation_path(conversations(:one_and_two))

    assert_response :not_found
  end

  test "opening a conversation clears the viewer's unread count" do
    sign_in users(:two)

    get conversation_path(conversations(:one_and_two))

    assert_equal 0, conversations(:one_and_two).participant_for(users(:two)).reload.unread_count
  end

  test "renders the inbox with a bounded number of queries" do
    sign_in users(:one)

    assert_queries_count(13) { get conversations_path }
  end

  test "renders a conversation with a bounded number of queries" do
    sign_in users(:one)

    assert_queries_count(11) { get conversation_path(conversations(:one_and_two)) }
  end

  test "creating a conversation with another user redirects to it" do
    sign_in users(:two)

    assert_difference("Conversation.count", 1) do
      post conversations_path, params: { user_id: users(:admin).id }
    end

    assert_redirected_to conversation_path(Conversation.last)
  end

  test "creating a conversation twice with the same user reuses the existing one" do
    sign_in users(:one)

    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:two).id }
    end

    assert_redirected_to conversation_path(conversations(:one_and_two))
  end

  test "creating a conversation with yourself is rejected" do
    sign_in users(:one)

    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:one).id }
    end

    assert_redirected_to conversations_path
  end
end
