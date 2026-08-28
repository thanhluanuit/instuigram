require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  setup do
    attach_images_to_all_posts!
    sign_in_as users(:one)
    wait_for_page_to_settle
  end

  test "posting a comment in the popup adds it to the list and updates the feed's counter" do
    open_popup_for posts(:two)

    within ".post-modal" do
      fill_in "comment_body", with: "Great shot"
      click_button "Comment"

      assert_selector ".comment", text: "Great shot"
    end

    assert_selector "##{dom_id(posts(:two), :comments_count)}", text: "2 comments"
    assert_current_path root_path
  end

  test "deleting your own comment removes it and drops the feed's counter" do
    open_popup_for posts(:two)

    accept_confirm { find(".post-modal .delete-comment-icon").click }

    assert_selector ".post-modal .no-comments"
    assert_selector "##{dom_id(posts(:two), :comments_count)}", text: "0 comments"
  end

  private

  def open_popup_for(post)
    find("section.post", text: post.description).find(".comment-icon").execute_script("this.click()")

    assert_selector "turbo-frame#post_modal[complete] .post-modal", text: post.description
  end
end
