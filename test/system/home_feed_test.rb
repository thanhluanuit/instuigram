require "application_system_test_case"

class HomeFeedTest < ApplicationSystemTestCase
  setup do
    11.times { |n| create_post!(users(:one), description: "post #{n}") }
    sign_in_as users(:one)
    wait_for_page_to_settle
  end

  test "scrolling to the bottom of the feed loads the next page without a page reload" do
    assert_selector "section.post", count: 10
    assert_no_selector "section.post", text: "post 0"

    execute_script "window.scrollTo(0, document.body.scrollHeight)"

    assert_selector "section.post", count: 13
    assert_selector "section.post", text: "post 0"
    assert_selector "#feed_sentinel", text: "caught up"
    assert_no_selector "#feed_sentinel a"
  end
end
