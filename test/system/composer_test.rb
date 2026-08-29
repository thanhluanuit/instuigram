require "application_system_test_case"

class ComposerTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    wait_for_page_to_settle
  end

  test "the Post button stays disabled until a photo is attached" do
    assert_button "Post", disabled: true

    attach_file "post_image", browser_readable_fixture_file("test_image.png"), make_visible: true

    assert_button "Post", disabled: false
  end

  test "attaching a photo shows its filename in the composer" do
    assert_selector ".composer-filename", text: "No photo selected"

    attach_file "post_image", browser_readable_fixture_file("test_image.png"), make_visible: true

    assert_selector ".composer-filename", text: "test_image.png"
  end
end
