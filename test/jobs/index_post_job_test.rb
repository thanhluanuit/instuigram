require "test_helper"

class IndexPostJobTest < ActiveSupport::TestCase
  test "indexes the post's description and hashtag names into Elasticsearch" do
    post = create_post!(users(:one), description: "hello #world")

    IndexPostJob.perform_now(post.id)
    Post.__elasticsearch__.refresh_index!

    document = Post.__elasticsearch__.client.get(index: Post.index_name, id: post.id)

    assert_equal "hello #world", document["_source"]["description"]
    assert_equal [ "world" ], document["_source"]["hashtag_names"]
  end

  test "does nothing when the post no longer exists" do
    assert_nothing_raised { IndexPostJob.perform_now(-1) }
  end
end
