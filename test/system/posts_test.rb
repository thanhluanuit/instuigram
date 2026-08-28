require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
    wait_for_page_to_settle
  end

  test "creating a post from the composer shows it in the feed" do
    fill_in "post_description", with: "a fresh #capybara photo"
    attach_file "post_image", browser_readable_test_image, make_visible: true

    click_button "Post"

    assert_selector "section.post", text: "a fresh #capybara photo"
    assert_selector "section.post", count: 3
  end

  test "deleting your own post removes it from the feed" do
    find("section.post", text: posts(:one).description).find(".main-image-link").click

    accept_confirm { find(".delete-icon").click }

    assert_current_path user_path(users(:one))

    visit root_path

    assert_no_selector "section.post", text: posts(:one).description
  end

  private

  def browser_readable_test_image
    path = File.join(Dir.tmpdir, "instuigram_system_test_image.png")
    FileUtils.cp(file_fixture("test_image.png"), path)
    path
  end
end
