require "application_system_test_case"

class FollowsTest < ApplicationSystemTestCase
  setup do
    Post.find_each { |post| attach_test_image(post.image) }
    @other = users(:two)
    sign_in_as users(:one)
  end

  test "following a user flips the button and updates the follower count in place" do
    visit_profile

    assert_selector "##{dom_id(@other, :followers_count)}", text: "0 followers"

    click_button "Follow"

    assert_selector follow_button_selector, exact_text: "Following"
    assert_selector "##{dom_id(@other, :followers_count)}", text: "1 followers"
  end

  test "unfollowing reverts the button and the follower count" do
    visit_profile

    click_button "Follow"
    assert_selector follow_button_selector, exact_text: "Following"

    click_button "Following"

    assert_selector follow_button_selector, exact_text: "Follow"
    assert_selector "##{dom_id(@other, :followers_count)}", text: "0 followers"
  end

  test "following from a post in the feed flips that post's button" do
    visit root_path
    wait_for_page_to_settle

    assert_selector "section.post #{follow_button_selector}", exact_text: "Follow", count: 1

    click_button "Follow"

    assert_selector "section.post #{follow_button_selector}", exact_text: "Following", count: 1
  end

  test "following in one tab flips the button in another tab" do
    visit root_path
    wait_for_page_to_settle

    using_session :second_tab do
      sign_in_as users(:one)
      visit_profile
      assert_selector follow_button_selector, exact_text: "Follow"
    end

    click_button "Follow"

    using_session :second_tab do
      assert_selector follow_button_selector, exact_text: "Following"
    end
  end

  private

  def visit_profile
    visit user_path(@other)
    wait_for_page_to_settle
  end

  def follow_button_selector
    "[data-follow-user-id='#{@other.id}'] button"
  end
end
