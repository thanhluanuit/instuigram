require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  setup { index_all_posts! }

  test "finds the same posts whether or not the query is written with a leading #" do
    hashtag_results = search_ids("##{hash_tags(:one).name}")
    plain_results   = search_ids(hash_tags(:one).name)

    assert_includes hashtag_results, posts(:one).id
    assert_equal plain_results, hashtag_results
  end

  test "ranks a hashtag match above a description-only match" do
    tagged    = create_post!(users(:one), description: "a photo of a #capybara at dusk")
    described = create_post!(users(:one), description: "capybara spotted by the river")
    index_pending_posts!

    assert_equal [ tagged.id, described.id ], search_ids("capybara")
  end

  test "tolerates a single-character typo in the query" do
    assert_includes search_ids("sunst"), posts(:one).id
  end

  private

  def search_ids(query)
    Post.search(query).records.map(&:id)
  end
end
