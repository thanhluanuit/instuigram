require "test_helper"

class UsersHelperTest < ActionView::TestCase
  test "returns the URL unchanged when it is valid" do
    assert_equal "https://example.com", external_url("https://example.com")
  end

  test "returns nil for an invalid URL" do
    assert_nil external_url("http://a b.com")
  end

  test "returns nil for a javascript: URI" do
    assert_nil external_url("javascript:alert(document.cookie)")
  end

  test "returns nil for a data: URI" do
    assert_nil external_url("data:text/html,<script>alert(1)</script>")
  end

  test "returns an empty string for a blank URL" do
    assert_equal "", external_url("")
  end

  test "user_monogram uses the first character of the username, upcased" do
    assert_equal "U", user_monogram(users(:one))
  end

  test "user_monogram falls back to the email when the username is blank" do
    assert_equal "U", user_monogram(User.new(username: "", email: "user_three@instuigram.com"))
  end

  test "user_monogram is blank when the user has neither a username nor an email" do
    assert_equal "", user_monogram(User.new)
  end

  test "profile_path_for returns the canonical profile path for the current user" do
    @current_user = users(:one)

    assert_equal profile_path, profile_path_for(users(:one))
  end

  test "profile_path_for returns the id-bearing path for another user" do
    @current_user = users(:one)

    assert_equal user_path(users(:two)), profile_path_for(users(:two))
  end

  test "profile_path_for returns the id-bearing path for an anonymous visitor" do
    assert_equal user_path(users(:one)), profile_path_for(users(:one))
  end

  private

  def current_user
    @current_user
  end
end
