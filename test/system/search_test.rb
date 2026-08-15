require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  test "searching by hashtag shows only the matching post" do
    attach_test_image(posts(:one).image)
    sign_in_as users(:one)

    fill_in "query", with: "#sunset"
    find_field("query").send_keys(:enter)

    assert_selector "h1", text: "Top Posts"
    assert_selector ".user-images .wrapper", count: 1
  end
end
