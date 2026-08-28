require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  setup { index_all_posts! }

  test "finds the same posts whether or not the query is written with a leading #" do
    hashtag_results = Post.search("##{hash_tags(:one).name}").records.map(&:id)
    plain_results   = Post.search(hash_tags(:one).name).records.map(&:id)

    assert_includes hashtag_results, posts(:one).id
    assert_equal plain_results, hashtag_results
  end

  test "ranks a hashtag match above a description-only match" do
    tagged, described = index_posts(
      "a photo of a #capybara at dusk",
      "capybara spotted by the river"
    )

    results = Post.search("capybara").records.map(&:id)

    assert_equal [ tagged.id, described.id ], results
  end

  test "tolerates a single-character typo in the query" do
    results = Post.search("sunst").records.map(&:id)

    assert_includes results, posts(:one).id
  end

  private

  def index_posts(*descriptions)
    posts = descriptions.map { |description| create_post!(users(:one), description: description) }
    perform_enqueued_jobs
    Post.__elasticsearch__.refresh_index!
    posts
  end
end
