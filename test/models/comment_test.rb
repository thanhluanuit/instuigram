require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
    @user = users(:one)
  end

  test "is valid with a post, a user, and a body" do
    assert build_comment.valid?
  end

  test "is invalid without a body" do
    assert_not build_comment(body: nil).valid?
  end

  test "is invalid without a post" do
    assert_not build_comment(post: nil).valid?
  end

  test "is invalid without a user" do
    assert_not build_comment(user: nil).valid?
  end

  test "with the :one fixture, belongs to the :one post" do
    assert_equal posts(:one), comments(:one).post
  end

  test "with the :one fixture, belongs to the :two user" do
    assert_equal users(:two), comments(:one).user
  end

  test "has many reactions through the polymorphic reactable association" do
    assert_equal [ reactions(:two) ], comments(:one).reactions
  end

  test "creating a comment increments its post's comments_count" do
    assert_difference("@post.reload.comments_count", 1) { build_comment.save! }
  end

  test "destroying a comment decrements its post's comments_count" do
    comment = build_comment
    comment.save!

    assert_difference("@post.reload.comments_count", -1) { comment.destroy }
  end

  test "destroying a comment destroys its reactions" do
    comment = comments(:one)
    reaction_id = reactions(:two).id

    assert_difference("Reaction.count", -1) { comment.destroy }
    assert_not Reaction.exists?(reaction_id)
  end

  private

  def build_comment(post: @post, user: @user, body: "Great post!")
    Comment.new(post: post, user: user, body: body)
  end
end
