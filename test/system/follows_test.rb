require "application_system_test_case"

class FollowsTest < ApplicationSystemTestCase
  setup do
    attach_images_to_all_posts!
    @other = users(:two)
    sign_in_as users(:one)
    visit user_path(@other)
    wait_for_page_to_settle
  end

  test "following a user flips the button and updates the follower count in place" do
    assert_selector "##{dom_id(@other, :followers_count)}", text: "0 followers"

    click_button "Follow"

    assert_selector "##{dom_id(@other, :follow)} button", exact_text: "Following"
    assert_selector "##{dom_id(@other, :followers_count)}", text: "1 followers"
  end

  test "unfollowing reverts the button and the follower count" do
    click_button "Follow"
    assert_selector "##{dom_id(@other, :follow)} button", exact_text: "Following"

    click_button "Following"

    assert_selector "##{dom_id(@other, :follow)} button", exact_text: "Follow"
    assert_selector "##{dom_id(@other, :followers_count)}", text: "0 followers"
  end
end
