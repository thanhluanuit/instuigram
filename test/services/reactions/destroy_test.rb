require "test_helper"

class Reactions::DestroyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @post = posts(:two)
  end

  test "destroys the user's own reaction on the post" do
    react

    reaction = assert_difference("Reaction.count", -1) { destroy_reaction }

    assert reaction.destroyed?
    assert_equal @user, reaction.user
  end

  test "broadcasts the decremented reactions_count to everyone viewing the post" do
    react

    assert_broadcast_on(post_stream(@post), reactions_count: 0) { destroy_reaction }
  end

  test "broadcasts the unliked state to the user's own stream" do
    react

    assert_broadcast_on(user_reaction_stream(@post, @user), liked: false) { destroy_reaction }
  end

  test "returns nil and destroys nothing when the user has not reacted" do
    reaction = assert_no_difference("Reaction.count") { destroy_reaction }

    assert_nil reaction
  end

  test "broadcasts nothing when the user has not reacted" do
    assert_no_broadcasts(post_stream(@post)) { destroy_reaction }
  end

  test "leaves another user's reaction on the same post in place" do
    react
    others = Reaction.create!(user: users(:two), reactable: Post.find(@post.id))

    destroy_reaction

    assert others.reload.persisted?
  end

  private

  def react(user: @user, post: @post)
    Reactions::Create.call(user: user, post: post, reaction_type: "like")
  end

  def destroy_reaction(user: @user, post: @post)
    Reactions::Destroy.call(user: user, post: post)
  end
end
