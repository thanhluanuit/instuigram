require "test_helper"

class DeindexPostJobTest < ActiveSupport::TestCase
  test "removes the post's document from Elasticsearch" do
    post = create_post!(users(:one), description: "temporary post")
    IndexPostJob.perform_now(post.id)
    Post.__elasticsearch__.refresh_index!

    DeindexPostJob.perform_now(post.id)
    Post.__elasticsearch__.refresh_index!

    assert_raises(Elastic::Transport::Transport::Errors::NotFound) do
      Post.__elasticsearch__.client.get(index: Post.index_name, id: post.id)
    end
  end

  test "does nothing when the document doesn't exist" do
    assert_nothing_raised { DeindexPostJob.perform_now(-1) }
  end
end
