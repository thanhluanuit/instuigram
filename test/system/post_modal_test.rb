require "application_system_test_case"

class PostModalTest < ApplicationSystemTestCase
  setup do
    attach_images_to_all_posts!
    sign_in_as users(:one)
    assert_selector "section.post", count: 2
    wait_for_page_to_settle
  end

  test "the comment icon opens a popup with the post and its comments without leaving the feed" do
    assert_selector "##{dom_id(posts(:two), :comments_count)}", text: "1 comment"

    assert_no_navigation do
      open_popup_for posts(:two)

      assert_selector ".post-modal", text: comments(:two).body
      assert_selector ".post-modal ##{dom_id(posts(:two), :comment_form_body)}"
    end

    assert_current_path root_path
  end

  test "closing the popup returns to the feed" do
    assert_no_navigation do
      open_popup_for posts(:two)

      find(".post-modal-close").execute_script("this.click()")

      assert_no_selector ".post-modal"
      assert_selector "section.post", count: 2
    end

    assert_current_path root_path
  end

  test "clicking the popup backdrop closes it" do
    assert_no_navigation do
      open_popup_for posts(:two)

      find(".post-modal").execute_script("this.click()")

      assert_no_selector ".post-modal"
      assert_selector "section.post", count: 2
    end

    assert_current_path root_path
  end

  test "pressing Escape closes the popup" do
    assert_no_navigation do
      open_popup_for posts(:two)

      find("body").send_keys(:escape)

      assert_no_selector ".post-modal"
      assert_no_selector "body.modal-open"
    end

    assert_current_path root_path
  end

  private

  def open_popup_for(post)
    find("section.post", text: post.description).find(".comment-icon").execute_script("this.click()")

    assert_selector "turbo-frame#post_modal[complete] .post-modal", text: post.description
  end
end
