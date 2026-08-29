require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  MATCHING_MARKER = "pagination marker".freeze

  setup { index_all_posts! }

  test "with a blank query, shows no matching posts and no result header" do
    get search_path

    assert_select ".empty-state p", /No posts match/
    assert_select ".search-page__header", false
  end

  test "echoes the query back as a chip in the result header" do
    get search_path(query: "sunset")

    assert_select ".search-page__term", "sunset"
  end

  test "with a hashtag query, finds only posts tagged with that hashtag" do
    get search_path(query: "##{hash_tags(:one).name}")

    assert_select ".page-title", "Top posts"
    assert_select "a[href=?]", post_path(posts(:one))
    assert_not_includes response.body, post_path(posts(:two))
  end

  test "with a hashtag query that matches nothing, shows no matching posts" do
    get search_path(query: "#nonexistent")

    assert_select ".empty-state p", /No posts match/
  end

  test "with a text query matching a post's description, finds only that post" do
    get search_path(query: "sunset")

    assert_select "a[href=?]", post_path(posts(:one))
    assert_not_includes response.body, post_path(posts(:two))
  end

  test "with a text query matching nothing, shows no matching posts" do
    get search_path(query: "no post has this description")

    assert_select ".empty-state p", /No posts match/
  end

  test "paginates matching posts 10 per page" do
    index_matching_posts(11)

    get search_path(query: MATCHING_MARKER)
    assert_select ".thumbnail-grid .wrapper", count: 10

    get search_path(query: MATCHING_MARKER, page: 2)
    assert_select ".thumbnail-grid .wrapper", count: 1
  end

  test "with a page past the last one, shows no matching posts" do
    index_matching_posts(1)

    get search_path(query: MATCHING_MARKER, page: 99)

    assert_response :success
    assert_select ".empty-state p", /No posts match/
  end

  test "with a multi-word query, finds the post whose description contains those words" do
    get search_path(query: "walk beach")

    assert_select ".page-title", "Top posts"
    assert_select "a[href=?]", post_path(posts(:two))
  end

  test "avoids N+1 queries when rendering multiple matching posts" do
    create_post!(users(:one), description: "shared marker one")
    create_post!(users(:two), description: "shared marker two")
    index_pending_posts!

    assert_queries_count(3) { get search_path(query: "shared marker") }

    assert_select ".page-title", "Top posts"
    assert_select ".thumbnail-grid .wrapper", count: 2
  end

  private

  def index_matching_posts(count)
    count.times { |n| create_post!(users(:one), description: "#{MATCHING_MARKER} #{n}") }
    index_pending_posts!
  end
end
