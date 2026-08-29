require "application_system_test_case"

class ReactionsTest < ApplicationSystemTestCase
  setup do
    attach_images_to_all_posts!
    sign_in_as users(:one)
    wait_for_page_to_settle
  end

  test "liking a post from the feed swaps the heart in place without leaving the feed" do
    within feed_post(posts(:two)) do
      assert_selector ".reaction-icon[aria-label='Like']"

      find(".reaction-icon").click

      assert_selector ".reaction-icon.liked[aria-label='Unlike']"
      assert_selector ".reactions-count", text: "1 likes"
    end

    assert_current_path root_path
  end

  test "unliking a post restores the empty heart" do
    within feed_post(posts(:two)) do
      find(".reaction-icon").click
      assert_selector ".reaction-icon.liked"

      find(".reaction-icon").click

      assert_selector ".reaction-icon[aria-label='Like']"
      assert_no_selector ".reaction-icon.liked"
      assert_selector ".reactions-count", text: "0 likes"
    end
  end

  test "another user's like updates the like count in an open feed" do
    within(feed_post(posts(:two))) { assert_selector ".reactions-count", text: "0 likes" }
    wait_for_cable("reactions")

    assert_no_navigation do
      within_session_as(:two, users(:two)) do
        wait_for_page_to_settle
        within(feed_post(posts(:two))) { find(".reaction-icon").click }
        within(feed_post(posts(:two))) { assert_selector ".reaction-icon.liked" }
      end

      within(feed_post(posts(:two))) { assert_selector ".reactions-count", text: "1 likes" }
    end
  end

  private

  def feed_post(post)
    find("section.post", text: post.description)
  end
end
