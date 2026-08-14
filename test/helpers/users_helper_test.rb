require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  test "returns the URL unchanged when it is valid" do
    assert_equal "https://example.com", external_url("https://example.com")
  end

  test "returns nil for an invalid URL" do
    assert_nil external_url("http://a b.com")
  end

  test "returns an empty string for a blank URL" do
    assert_equal "", external_url("")
  end
end
