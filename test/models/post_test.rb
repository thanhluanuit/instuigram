require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "is valid with a description, a user, and an attached image" do
    assert build_post.valid?
  end

  test "is valid without a description" do
    assert build_post(description: nil).valid?
  end

  test "is invalid without an attached image" do
    post = build_post(attach_image: false)

    assert_not post.valid?
    assert_includes post.errors[:image], "can't be blank"
  end

  test "is invalid with a non-image attachment" do
    post = build_post(attach_image: false)
    attach_non_image_file(post.image)

    assert_not post.valid?
    assert_includes post.errors[:image], "must be a PNG, JPEG, or WebP"
  end

  test "is invalid with an image over the size limit" do
    post = build_post(attach_image: false)
    attach_oversized_image(post.image)

    assert_not post.valid?
    assert_includes post.errors[:image], "must be smaller than 10MB"
  end

  test "is invalid without a user" do
    assert_not build_post(user: nil).valid?
  end

  test "with the :one fixture, belongs to the :one user" do
    assert_equal users(:one), posts(:one).user
  end

  test "with the :two fixture, belongs to the :two user" do
    assert_equal users(:two), posts(:two).user
  end

  test "with the :one fixture, has an attached image" do
    assert posts(:one).image.attached?
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

  test "extracts every #word token from the description" do
    post = build_post(description: "loving this #sunset over the #beach today", attach_image: false)

    assert_equal %w[sunset beach], post.extract_name_hash_tags
  end

  test "extracts no tags from a description with none" do
    post = build_post(description: "just a plain caption", attach_image: false)

    assert_empty post.extract_name_hash_tags
  end

  test "creates a HashTag for each new #word when saved" do
    post = build_post(description: "great #mountains and the #ocean")

    assert_difference("HashTag.count", 2) { post.save! }
  end

  test "associates the saved post with the extracted hash tags" do
    post = build_post(description: "great #mountains and the #ocean")
    post.save!

    assert_equal %w[mountains ocean], post.hash_tags.pluck(:name).sort
  end

  test "reuses an existing HashTag instead of creating a duplicate" do
    post = build_post(description: "great #sunset")

    assert_no_difference("HashTag.count") { post.save! }
    assert_equal [ hash_tags(:one) ], post.hash_tags
  end

  test "does not create duplicate post_hash_tags when a tag repeats in the description" do
    post = build_post(description: "so good #sunset #sunset")

    assert_difference("PostHashTag.count", 1) { post.save! }
  end

  test "creates no HashTag records when the description has no tags" do
    post = build_post(description: "no tags here")

    assert_no_difference("HashTag.count") { post.save! }
  end

  test "does not create additional hash tags when an existing post is updated" do
    post = build_post(description: "great #sunset")
    post.save!

    assert_no_difference("HashTag.count") { post.update!(description: "great #sunset and #mountains") }
  end

  test "enqueues an IndexPostJob for the saved post when created" do
    post = build_post(description: "great #sunset")

    assert_enqueued_with(job: IndexPostJob) { post.save! }
  end

  test "does not enqueue an IndexPostJob when an existing post is updated" do
    post = build_post(description: "great #sunset")
    post.save!

    assert_no_enqueued_jobs(only: IndexPostJob) { post.update!(description: "updated") }
  end

  test "enqueues a DeindexPostJob for the destroyed post" do
    post = build_post(description: "great #sunset")
    post.save!

    assert_enqueued_with(job: DeindexPostJob, args: [ post.id ]) { post.destroy }
  end

  test "builds an indexed document from the id, description, created_at, and hashtag names" do
    post = build_post(description: "great #sunset at the #beach")
    post.save!

    document = post.as_indexed_json

    assert_equal post.id, document["id"]
    assert_equal "great #sunset at the #beach", document["description"]
    assert_equal post.created_at.as_json, document["created_at"]
    assert_equal %w[beach sunset], document["hashtag_names"].sort
  end

  test "search returns nil for a blank query" do
    assert_nil Post.search("")
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

  private

  def build_post(user: @user, description: "hello world", attach_image: true)
    post = Post.new(user: user, description: description)
    attach_test_image(post.image) if attach_image
    post
  end
end
