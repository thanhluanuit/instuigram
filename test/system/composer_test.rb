require "application_system_test_case"

class ComposerTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    wait_for_page_to_settle
  end

  test "the Post button stays disabled until a photo is attached" do
    assert_button "Share", disabled: true

    attach_file "post_image", browser_readable_fixture_file("test_image.png"), make_visible: true

    assert_button "Share", disabled: false
  end

  test "attaching a photo shows its filename in the composer" do
    assert_selector ".composer-filename", text: "Drag a photo here, or click to browse"

    attach_file "post_image", browser_readable_fixture_file("test_image.png"), make_visible: true

    assert_selector ".composer-filename", text: "test_image.png"
  end

  test "attaching a photo renders a preview rather than being blocked by the content security policy" do
    attach_file "post_image", browser_readable_fixture_file("test_image.png"), make_visible: true

    assert_selector ".composer-preview"
    assert page.evaluate_script("(() => { const i = document.querySelector('.composer-preview'); return i.complete && i.naturalWidth > 0 })()"),
           "the blob: preview did not load — check img_src in the content security policy"
  end

  test "a file the server would reject is refused at the picker, not on submit" do
    attach_file "post_image", browser_readable_fixture_file("not_an_image.txt"), make_visible: true

    assert_selector ".composer-error", text: /is not a PNG, JPEG or WebP/
    assert_selector ".composer-filename", text: "Drag a photo here, or click to browse"
    assert_button "Share", disabled: true
  end

  test "choosing a valid photo after a rejected one clears the error" do
    attach_file "post_image", browser_readable_fixture_file("not_an_image.txt"), make_visible: true
    assert_selector ".composer-error", text: /is not a PNG/

    attach_file "post_image", browser_readable_fixture_file("test_image.png"), make_visible: true

    assert_no_selector ".composer-error", visible: true
    assert_button "Share", disabled: false
  end

  test "the caption's hashtags appear as chips as you type" do
    assert_selector ".composer-tag", text: "add #hashtags"

    fill_in "post_description", with: "sunset over #hanoi #travel"

    assert_selector ".composer-tag", text: "#hanoi"
    assert_selector ".composer-tag", text: "#travel"
    assert_no_selector ".composer-tag", text: "add #hashtags"
  end

  test "the character counter tracks the caption length" do
    assert_selector ".composer-counter", text: "0 / 2200"

    fill_in "post_description", with: "hello"

    assert_selector ".composer-counter", text: "5 / 2200"
  end
end
