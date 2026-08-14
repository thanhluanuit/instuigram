require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "with a blank query, shows no matching posts" do
    get search_path

    assert_select "h1", "Oop! No matching posts ..."
  end

  test "with a hashtag query, finds posts tagged with that hashtag" do
    get search_path(query: "##{hash_tags(:one).name}")

    assert_select "h1", "Top Posts"
    assert_select "a[href=?]", post_path(posts(:one))
  end

  test "with a hashtag query that matches nothing, shows no matching posts" do
    get search_path(query: "#nonexistent")

    assert_select "h1", "Oop! No matching posts ..."
  end

  test "with a text query matching a post's description, finds it" do
    get search_path(query: posts(:one).description)

    assert_select "h1", "Top Posts"
  end

  test "with a text query matching nothing, shows no matching posts" do
    get search_path(query: "no post has this description")

    assert_select "h1", "Oop! No matching posts ..."
  end
end
