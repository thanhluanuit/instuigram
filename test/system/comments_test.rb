require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  setup do
    attach_images_to_all_posts!
    sign_in_as users(:one)
    assert_selector "section.post", count: 2
    wait_for_page_to_settle
  end

  test "the comment icon opens a popup with the post and its comments without leaving the feed" do
    assert_selector "##{dom_id(posts(:two), :comments_count)}", text: "1 comment"

    open_popup_for posts(:two)

    assert_selector ".post-modal", text: comments(:two).body
    assert_selector ".post-modal #comment_body"
    assert_current_path root_path
  end

  test "closing the popup returns to the feed" do
    open_popup_for posts(:two)

    find(".post-modal-close").execute_script("this.click()")

    assert_no_selector ".post-modal"
    assert_current_path root_path
    assert_selector "section.post", count: 2
  end

  private

  def open_popup_for(post)
    find("section.post", text: post.description).find(".comment-icon").execute_script("this.click()")

    assert_selector "turbo-frame#post_modal[complete] .post-modal", text: post.description
  end
end
