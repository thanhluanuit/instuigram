# frozen_string_literal: true

require "test_helper"

class KeyableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "assigns a key when the record is created" do
    post = create_post!(@user, description: "a keyed post")

    assert_match(/\A[0-9a-f-]{36}\z/, post.key)
  end

  test "assigns a different key to every record" do
    keys = 3.times.map { create_post!(@user, description: "another post").key }

    assert_equal 3, keys.uniq.size
  end

  test "does not change the key when an existing record is updated" do
    post = create_post!(@user, description: "a keyed post")

    assert_no_changes -> { post.reload.key } do
      post.update!(description: "an edited post")
    end
  end

  test "ignores a client-supplied key so it can never be chosen" do
    post = Post.new(user: @user, description: "a smuggled key", key: "chosen-by-the-client")
    attach_test_image(post.image)
    post.save!

    assert_not_equal "chosen-by-the-client", post.key
  end

  test "assigns a key to every model that includes the concern" do
    conversation = Conversation.create!(participants_key: "1-2")
    message = conversation.messages.create!(user: @user, body: "hello")
    comment = posts(:one).comments.create!(user: @user, body: "nice")

    assert_not_nil @user.key
    assert_not_nil conversation.key
    assert_not_nil message.key
    assert_not_nil comment.key
  end
end
