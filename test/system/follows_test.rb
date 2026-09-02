require "application_system_test_case"

class FollowsTest < ApplicationSystemTestCase
  setup do
    @other = users(:two)
    sign_in_as users(:one)
  end

  test "following a user flips the button and updates the follower count in place" do
    visit_profile

    assert_selector "##{dom_id(@other, :followers_count)}", text: /0 followers/i

    find(profile_follow_button_selector).click

    assert_selector profile_follow_button_selector, exact_text: "Following"
    assert_selector "##{dom_id(@other, :followers_count)}", text: /1 followers/i
  end

  test "unfollowing reverts the button and the follower count" do
    visit_profile

    find(profile_follow_button_selector).click
    assert_selector profile_follow_button_selector, exact_text: "Following"

    find(profile_follow_button_selector).click

    assert_selector profile_follow_button_selector, exact_text: "Follow"
    assert_selector "##{dom_id(@other, :followers_count)}", text: /0 followers/i
  end

  test "following from a post in the feed leaves the button in place to undo it" do
    visit root_path
    wait_for_page_to_settle

    assert_selector "section.post #{follow_button_selector}", exact_text: "Follow", count: 1

    find("section.post #{follow_button_selector}").click
    assert_selector "section.post #{follow_button_selector}", exact_text: "Following", count: 1

    find("section.post #{follow_button_selector}").click

    assert_selector "section.post #{follow_button_selector}", exact_text: "Follow", count: 1
  end

  test "a followed user's posts carry no follow button on the next page load" do
    visit root_path
    wait_for_page_to_settle
    find("section.post #{follow_button_selector}").click
    assert_selector "section.post #{follow_button_selector}", exact_text: "Following"

    visit root_path
    wait_for_page_to_settle

    assert_no_selector "section.post #{follow_button_selector}"
  end

  test "following in one tab flips the button in another tab" do
    visit root_path
    wait_for_page_to_settle

    using_session :second_tab do
      sign_in_as users(:one)
      visit_profile
      assert_selector profile_follow_button_selector, exact_text: "Follow"
    end

    find("section.post #{follow_button_selector}").click

    using_session :second_tab do
      assert_selector profile_follow_button_selector, exact_text: "Following"
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

  def profile_follow_button_selector
    ".profile-header #{follow_button_selector}"
  end
end
