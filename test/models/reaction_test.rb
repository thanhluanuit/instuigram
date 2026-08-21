require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  test "is valid with a user, a reactable, and a reaction_type" do
    assert build_reaction.valid?
  end

  test "is invalid without a user" do
    assert_not build_reaction(user: nil).valid?
  end

  test "is invalid without a reactable" do
    assert_not build_reaction(reactable: nil).valid?
  end

  test "defaults to the like reaction_type" do
    assert_equal "like", Reaction.new.reaction_type
  end

  test "with the :one fixture, reacts to the :one post" do
    assert_equal posts(:one), reactions(:one).reactable
  end

  test "with the :two fixture, reacts to the :one comment" do
    assert_equal comments(:one), reactions(:two).reactable
  end

  test "is invalid when the same user reacts to the same reactable twice" do
    duplicate = Reaction.new(user: reactions(:one).user, reactable: reactions(:one).reactable, reaction_type: :haha)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "allows the same user to react to a post and a comment separately" do
    post_reaction = build_reaction(reactable: @post, user: @user)
    comment_reaction = build_reaction(reactable: comments(:two), user: @user)

    assert post_reaction.valid?
    assert comment_reaction.valid?
  end

  test "allows different users to react to the same reactable" do
    assert build_reaction(user: users(:one), reactable: posts(:two)).valid?
    assert build_reaction(user: users(:two), reactable: posts(:two)).valid?
  end

  test "creating a reaction on a post increments the post's reactions_count" do
    assert_difference(-> { posts(:two).reactions_count }, 1) do
      build_reaction(reactable: posts(:two)).save!
      posts(:two).reload
    end
  end

  test "creating a reaction on a comment increments the comment's reactions_count" do
    assert_difference(-> { comments(:two).reactions_count }, 1) do
      build_reaction(reactable: comments(:two)).save!
      comments(:two).reload
    end
  end

  test "destroying a reaction decrements its reactable's reactions_count" do
    reaction = build_reaction(reactable: posts(:two))
    reaction.save!
    posts(:two).reload

    assert_difference(-> { posts(:two).reactions_count }, -1) do
      reaction.destroy
      posts(:two).reload
    end
  end

  test "creating a reaction on a post broadcasts the new reactions_count to PostChannel" do
    assert_broadcast_on(post_stream(posts(:two)), reactions_count: 1) do
      build_reaction(reactable: posts(:two)).save!
    end
  end

  test "destroying a reaction on a post broadcasts the new reactions_count to PostChannel" do
    reaction = build_reaction(reactable: posts(:two))
    reaction.save!

    assert_broadcast_on(post_stream(posts(:two)), reactions_count: 0) do
      reaction.destroy
    end
  end

  test "creating a reaction on a comment does not broadcast to PostChannel" do
    assert_no_broadcasts(post_stream(comments(:two))) do
      build_reaction(reactable: comments(:two)).save!
    end
  end

  test "creating a reaction on a post broadcasts the reacting user's own liked state" do
    assert_broadcast_on(user_reaction_stream(posts(:two), @user), liked: true) do
      build_reaction(reactable: posts(:two)).save!
    end
  end

  test "destroying a reaction on a post broadcasts the reacting user's own unliked state" do
    reaction = build_reaction(reactable: posts(:two))
    reaction.save!

    assert_broadcast_on(user_reaction_stream(posts(:two), @user), liked: false) do
      reaction.destroy
    end
  end

  test "reacting to a post does not broadcast a liked state to a different user's stream" do
    assert_no_broadcasts(user_reaction_stream(posts(:two), users(:two))) do
      build_reaction(reactable: posts(:two)).save!
    end
  end

  private

  def build_reaction(user: @user, reactable: @post, reaction_type: :like)
    Reaction.new(user: user, reactable: reactable, reaction_type: reaction_type)
  end

  def post_stream(reactable)
    PostChannel.broadcasting_for(reactable)
  end

  def user_reaction_stream(reactable, user)
    PostChannel.broadcasting_for([ reactable, user ])
  end
end
