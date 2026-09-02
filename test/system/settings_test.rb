require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    attach_images_to_all_posts!
    sign_in_as users(:one)
    visit edit_user_path(users(:one))
    wait_for_page_to_settle
  end

  test "selecting a settings tab opens that tab's own pane" do
    click_link "Privacy and Security"

    assert_selector "#v-pills-privacy.active", text: "Privacy and Security"
  end

  test "selecting a settings tab deselects the Edit Profile link" do
    click_link "Manage Contacts"

    assert_no_selector ".user-edit-page__nav .nav-link.active", text: "Edit Profile"
  end

  test "selecting a settings tab hides the profile form" do
    click_link "Authorized Applications"

    assert_no_selector "#v-pills-home.active"
  end
end
