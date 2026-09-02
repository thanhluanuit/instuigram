require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, redirects the inbox to sign in" do
    get conversations_path

    assert_redirected_to new_user_session_path
  end

  test "when unauthenticated, creates no conversation" do
    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:two).key }
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

  test "shows a participant's uploaded avatar in their inbox row" do
    attach_test_image(users(:two).avatar)
    sign_in users(:one)

    get conversations_path

    assert_select ".conversation-row__avatar img[alt=?]", users(:two).username
  end

  test "falls back to the monogram for a participant with no avatar" do
    sign_in users(:one)

    get conversations_path

    assert_select ".conversation-row__avatar .avatar-monogram"
  end

  test "renders the aside on the inbox" do
    sign_in users(:one)

    get conversations_path

    assert_select "aside.app-shell__aside .aside-account__name", text: users(:one).username
  end

  test "renders the aside on a conversation reached by a turbo form redirect" do
    sign_in users(:one)

    get conversation_path(conversations(:one_and_two)),
        headers: { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    assert_select "aside.app-shell__aside .aside-account__name", text: users(:one).username
  end

  test "renders the inbox with a bounded number of queries" do
    sign_in users(:one)

    assert_queries_count(14) { get conversations_path }
  end

  test "renders a conversation with a bounded number of queries" do
    sign_in users(:one)

    assert_queries_count(13) { get conversation_path(conversations(:one_and_two)) }
  end

  test "when unauthenticated, redirects the new message page to sign in" do
    get new_conversation_path

    assert_redirected_to new_user_session_path
  end

  test "the new message page lists other users but not yourself" do
    sign_in users(:one)

    get new_conversation_path

    assert_response :success
    assert_select ".conversations__list a[href=?]", user_path(users(:two))
    assert_select ".conversations__list a[href=?]", profile_path, false
  end

  test "the new message page filters users by username" do
    sign_in users(:one)

    get new_conversation_path, params: { query: "admin" }

    assert_response :success
    assert_select ".conversations__list a[href=?]", user_path(users(:admin))
    assert_select ".conversations__list a[href=?]", user_path(users(:two)), false
  end

  test "creating a conversation with another user redirects to it" do
    sign_in users(:two)

    assert_difference("Conversation.count", 1) do
      post conversations_path, params: { user_id: users(:admin).key }
    end

    assert_redirected_to conversation_path(Conversation.last)
  end

  test "creating a conversation twice with the same user reuses the existing one" do
    sign_in users(:one)

    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:two).key }
    end

    assert_redirected_to conversation_path(conversations(:one_and_two))
  end

  test "creating a conversation with yourself is rejected" do
    sign_in users(:one)

    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:one).key }
    end

    assert_redirected_to conversations_path
  end

  test "responds not found when the other participant is addressed by their database id" do
    sign_in users(:one)

    assert_no_difference("Conversation.count") do
      post conversations_path, params: { user_id: users(:admin).id }
    end

    assert_response :not_found
  end
end
