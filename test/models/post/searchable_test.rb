require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  test "finds the same posts whether or not the query is written with a leading #" do
    index_all_posts!

    hashtag_results = search_ids("##{hash_tags(:one).name}")
    plain_results   = search_ids(hash_tags(:one).name)

    assert_includes hashtag_results, posts(:one).id
    assert_equal plain_results, hashtag_results
  end

  test "ranks a hashtag match above a description-only match" do
    index_all_posts!
    tagged    = create_post!(users(:one), description: "a photo of a #capybara at dusk")
    described = create_post!(users(:one), description: "capybara spotted by the river")
    index_pending_posts!

    assert_equal [ tagged.id, described.id ], search_ids("capybara")
  end

  test "tolerates a single-character typo in the query" do
    index_all_posts!

    assert_includes search_ids("sunst"), posts(:one).id
  end

  test "enqueues an IndexPostJob for the saved post when created" do
    post = build_post(users(:one), description: "great #sunset")

    assert_enqueued_with(job: IndexPostJob) { post.save! }
  end

  test "does not enqueue an IndexPostJob when an existing post is updated" do
    post = build_post(users(:one), description: "great #sunset")
    post.save!

    assert_no_enqueued_jobs(only: IndexPostJob) { post.update!(description: "updated") }
  end

  test "enqueues a DeindexPostJob for the destroyed post" do
    post = build_post(users(:one), description: "great #sunset")
    post.save!

    assert_enqueued_with(job: DeindexPostJob, args: [ post.id ]) { post.destroy }
  end

  test "builds an indexed document from the id, description, created_at, and hashtag names" do
    post = build_post(users(:one), description: "great #sunset at the #beach")
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

  private

  def search_ids(query)
    Post.search(query).records.map(&:id)
  end
end
