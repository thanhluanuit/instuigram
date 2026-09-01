require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with an email and a password" do
    assert build_user.valid?
  end

  test "is invalid without an email" do
    assert_not build_user(email: nil).valid?
  end

  test "is invalid with a duplicate email" do
    assert_not build_user(email: users(:one).email).valid?
  end

  test "is invalid without a password" do
    assert_not build_user(password: nil).valid?
  end

  test "is invalid with a password shorter than the minimum length" do
    assert_not build_user(password: "12345").valid?
  end

  test "is invalid with a javascript: URI as website" do
    assert_not build_user(website: "javascript:alert(document.cookie)").valid?
  end

  test "is valid with an http(s) website" do
    assert build_user(website: "https://example.com").valid?
  end

  test "defaults to non-admin" do
    assert_not build_user.admin?
  end

  test "can be marked as admin" do
    user = build_user
    user.admin = true

    assert user.admin?
  end

  test "has many posts through the :one fixture" do
    assert_equal [ posts(:one) ], users(:one).posts
  end

  test "destroying a user destroys their posts" do
    user = users(:one)
    post_id = posts(:one).id

    assert_difference("Post.count", -1) { user.destroy }
    assert_not Post.exists?(post_id)
  end

  test "has many comments" do
    user = users(:one)
    comment = user.comments.create!(post: posts(:two), body: "Nice!")

    assert_includes user.comments, comment
  end

  test "has many reactions" do
    user = users(:one)
    reaction = user.reactions.create!(reactable: posts(:two), reaction_type: :love)

    assert_includes user.reactions, reaction
  end

  test "destroying a user destroys their comments" do
    user = users(:one)
    comment = user.comments.create!(post: posts(:two), body: "Nice!")
    comment_id = comment.id

    user.destroy

    assert_not Comment.exists?(comment_id)
  end

  test "destroying a user destroys their reactions" do
    user = users(:one)
    reaction = user.reactions.create!(reactable: posts(:two), reaction_type: :love)
    reaction_id = reaction.id

    user.destroy

    assert_not Reaction.exists?(reaction_id)
  end

  test "online? is true when last seen within the last minute" do
    users(:one).update_column(:last_seen_at, 30.seconds.ago)

    assert_predicate users(:one).reload, :online?
  end

  test "online? is false when last seen more than a minute ago" do
    users(:one).update_column(:last_seen_at, 2.minutes.ago)

    assert_not users(:one).reload.online?
  end

  test "online? is false when the user has never been seen" do
    assert_not users(:one).online?
  end

  test "unread_messages_count sums unread counts across all conversations" do
    assert_equal 1, users(:one).unread_messages_count
  end

  test "destroying a user destroys the conversations they were part of" do
    conversation_id = conversations(:one_and_two).id

    users(:two).destroy

    assert_not Conversation.exists?(conversation_id)
  end

  test "destroying a user leaves conversations they were not part of intact" do
    conversation_id = conversations(:one_and_admin).id

    users(:two).destroy

    assert Conversation.exists?(conversation_id)
  end

  test "destroying a user destroys the messages and participants of their conversations" do
    assert_difference("Message.count", -3) do
      assert_difference("ConversationParticipant.count", -2) do
        users(:two).destroy
      end
    end
  end

  test "matching_username finds users whose username contains the query, case-insensitively" do
    assert_includes User.matching_username("USER_T"), users(:two)
    assert_not_includes User.matching_username("USER_T"), users(:admin)
  end

  test "matching_username returns everyone when the query is blank" do
    assert_equal User.count, User.matching_username("  ").count
  end

  test "matching_username treats wildcard characters as literal text" do
    assert_empty User.matching_username("%")
  end

  test "suggested_for excludes the user themselves" do
    assert_not_includes User.suggested_for(users(:one)), users(:one)
  end

  test "suggested_for excludes users the given user already follows" do
    users(:one).following << users(:two)

    assert_not_includes User.suggested_for(users(:one)), users(:two)
    assert_includes User.suggested_for(users(:one)), users(:admin)
  end

  test "suggested_for excludes users whose username is nil or blank" do
    nameless = User.create!(email: "nameless@instuigram.com", password: "password123", username: nil)
    blank    = User.create!(email: "blank@instuigram.com", password: "password123", username: "")

    assert_not_includes User.suggested_for(users(:one)), nameless
    assert_not_includes User.suggested_for(users(:one)), blank
  end

  test "suggested_for orders the most followed users first" do
    users(:admin).update!(followers_count: 5)
    users(:two).update!(followers_count: 1)

    assert_equal [ users(:admin), users(:two) ], User.suggested_for(users(:one)).to_a
  end

  private

  def build_user(email: "new_user@example.com", password: "password123", username: "new_user", website: nil)
    User.new(email: email, password: password, username: username, website: website)
  end
end
