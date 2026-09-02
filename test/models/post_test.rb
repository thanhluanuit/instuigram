require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "is valid with a description, a user, and an attached image" do
    assert build_post(@user).valid?
  end

  test "is valid without a description" do
    assert build_post(@user, description: nil).valid?
  end

  test "is valid with a description at the length limit" do
    assert build_post(@user, description: "a" * Post::DESCRIPTION_LIMIT).valid?
  end

  test "is invalid with a description over the length limit" do
    post = build_post(@user, description: "a" * (Post::DESCRIPTION_LIMIT + 1))

    assert_not post.valid?
    assert_includes post.errors[:description], "is too long (maximum is #{Post::DESCRIPTION_LIMIT} characters)"
  end

  test "is invalid without a user" do
    assert_not build_post(nil).valid?
  end

  test "with the :one fixture, belongs to the :one user" do
    assert_equal users(:one), posts(:one).user
  end

  test "with the :two fixture, belongs to the :two user" do
    assert_equal users(:two), posts(:two).user
  end

  test "created_recently orders posts newest first" do
    older = travel_to(2.days.ago) { create_post!(@user, description: "older") }
    newer = travel_to(1.day.ago) { create_post!(@user, description: "newer") }

    ordered = Post.where(id: [ older.id, newer.id ]).created_recently.to_a

    assert_equal [ newer, older ], ordered
  end

  test "discoverable_for excludes the given user's own posts" do
    discoverable = Post.discoverable_for(@user)

    assert_not_includes discoverable, posts(:one)
    assert_includes discoverable, posts(:two)
  end

  test "discoverable_for excludes posts by users the given user already follows" do
    @user.following_relationships.create!(followed: users(:two))

    assert_not_includes Post.discoverable_for(@user), posts(:two)
  end

  test "discoverable_for ranks a more engaged post above a newer one" do
    popular = travel_to(2.days.ago) { create_post!(users(:two), description: "popular") }
    quiet   = travel_to(1.day.ago) { create_post!(users(:two), description: "quiet") }
    popular.reactions.create!(user: @user, reaction_type: :love)

    ordered = Post.discoverable_for(@user).where(id: [ popular.id, quiet.id ]).to_a

    assert_equal [ popular, quiet ], ordered
  end

  test "discoverable_for falls back to recency for equally engaged posts" do
    older = travel_to(2.days.ago) { create_post!(users(:two), description: "older") }
    newer = travel_to(1.day.ago) { create_post!(users(:two), description: "newer") }

    ordered = Post.discoverable_for(@user).where(id: [ older.id, newer.id ]).to_a

    assert_equal [ newer, older ], ordered
  end

  test "has many comments" do
    comment = posts(:one).comments.create!(user: @user, body: "Nice!")

    assert_includes posts(:one).comments, comment
  end

  test "has many reactions through the polymorphic reactable association" do
    reaction = posts(:one).reactions.create!(user: @user, reaction_type: :love)

    assert_includes posts(:one).reactions, reaction
  end

  test "destroying a post destroys its comments" do
    post = posts(:two)
    comment = post.comments.create!(user: @user, body: "Nice!")
    comment_id = comment.id

    post.destroy

    assert_not Comment.exists?(comment_id)
  end

  test "destroying a post destroys its reactions" do
    post = posts(:two)
    reaction = post.reactions.create!(user: @user, reaction_type: :love)
    reaction_id = reaction.id

    post.destroy

    assert_not Reaction.exists?(reaction_id)
  end

  test "destroying a post destroys its comments' reactions" do
    post = posts(:two)
    comment = post.comments.create!(user: @user, body: "Nice!")
    reaction = comment.reactions.create!(user: @user, reaction_type: :haha)
    reaction_id = reaction.id

    post.destroy

    assert_not Reaction.exists?(reaction_id)
  end
end
