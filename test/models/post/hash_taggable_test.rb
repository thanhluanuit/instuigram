require "test_helper"

class Post::HashTaggableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "creates a hash tag for every #word token in the description" do
    post = build_post(@user, description: "loving this #sunset over the #beach today")
    post.save!

    assert_equal %w[beach sunset], post.hash_tags.pluck(:name).sort
  end

  test "creates no hash tags for a description with none" do
    post = build_post(@user, description: "just a plain caption")
    post.save!

    assert_empty post.hash_tags
  end

  test "creates a HashTag for each new #word when saved" do
    post = build_post(@user, description: "great #mountains and the #ocean")

    assert_difference("HashTag.count", 2) { post.save! }
  end

  test "reuses an existing HashTag instead of creating a duplicate" do
    post = build_post(@user, description: "great #sunset")

    assert_no_difference("HashTag.count") { post.save! }
    assert_equal [ hash_tags(:one) ], post.hash_tags
  end

  test "does not create duplicate post_hash_tags when a tag repeats in the description" do
    post = build_post(@user, description: "so good #sunset #sunset")

    assert_difference("PostHashTag.count", 1) { post.save! }
  end

  test "creates no HashTag records when the description has no tags" do
    post = build_post(@user, description: "no tags here")

    assert_no_difference("HashTag.count") { post.save! }
  end

  test "does not create additional hash tags when an existing post is updated" do
    post = build_post(@user, description: "great #sunset")
    post.save!

    assert_no_difference("HashTag.count") { post.update!(description: "great #sunset and #mountains") }
  end
end
