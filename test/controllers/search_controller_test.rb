require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup { index_all_posts! }

  test "with a blank query, shows no matching posts" do
    get search_path

    assert_select "h1", "Oop! No matching posts ..."
  end

  test "with a hashtag query, finds only posts tagged with that hashtag" do
    get search_path(query: "##{hash_tags(:one).name}")

    assert_select "h1", "Top Posts"
    assert_select "a[href=?]", post_path(posts(:one))
    assert_not_includes response.body, post_path(posts(:two))
  end

  test "with a hashtag query that matches nothing, shows no matching posts" do
    get search_path(query: "#nonexistent")

    assert_select "h1", "Oop! No matching posts ..."
  end

  test "with a text query matching a post's description, finds only that post" do
    get search_path(query: "sunset")

    assert_select "a[href=?]", post_path(posts(:one))
    assert_not_includes response.body, post_path(posts(:two))
  end

  test "with a text query matching nothing, shows no matching posts" do
    get search_path(query: "no post has this description")

    assert_select "h1", "Oop! No matching posts ..."
  end

  test "avoids N+1 queries when rendering multiple matching posts" do
    perform_enqueued_jobs do
      create_post!(users(:one), description: "shared marker one")
      create_post!(users(:two), description: "shared marker two")
    end
    Post.__elasticsearch__.refresh_index!

    assert_queries_count(6) { get search_path(query: "shared marker") }

    assert_select "h1", "Top Posts"
    assert_select ".user-images .wrapper", count: 2
  end
end
