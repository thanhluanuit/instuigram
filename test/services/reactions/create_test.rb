require "test_helper"

class Reactions::CreateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @post = posts(:two)
  end

  test "creates a reaction owned by the user on the post" do
    reaction = assert_difference("Reaction.count", 1) { create_reaction }

    assert reaction.persisted?
    assert_equal @user, reaction.user
    assert_equal @post, reaction.reactable
    assert_equal "like", reaction.reaction_type
    assert reaction.previously_new_record?
  end

  test "reacting again updates the existing reaction instead of creating a second" do
    existing = create_reaction

    reaction = assert_no_difference("Reaction.count") { create_reaction(reaction_type: "love") }

    assert_equal existing, reaction
    assert_equal "love", reaction.reload.reaction_type
    assert_not reaction.previously_new_record?
  end

  test "broadcasts the new reactions_count to everyone viewing the post" do
    assert_broadcast_on(post_stream(@post), reactions_count: 1) { create_reaction }
  end

  test "broadcasts the count from the database, not the caller's stale copy" do
    Reaction.create!(user: users(:two), reactable: Post.find(@post.id))

    assert_broadcast_on(post_stream(@post), reactions_count: 2) { create_reaction }
  end

  test "broadcasts the reacting user's liked state to their own stream" do
    assert_broadcast_on(user_reaction_stream(@post, @user), liked: true) { create_reaction }
  end

  test "does not broadcast a liked state to a different user's stream" do
    assert_no_broadcasts(user_reaction_stream(@post, users(:two))) { create_reaction }
  end

  test "reacting again broadcasts nothing" do
    create_reaction

    assert_no_broadcasts(post_stream(@post)) { create_reaction(reaction_type: "love") }
  end

  private

  def create_reaction(user: @user, post: @post, reaction_type: "like")
    Reactions::Create.call(user: user, post: post, reaction_type: reaction_type)
  end
end
