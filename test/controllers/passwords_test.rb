# frozen_string_literal: true

require "test_helper"

class PasswordsTest < ActionDispatch::IntegrationTest
  test "the forgot password page renders the email field" do
    get new_user_password_path

    assert_select "input[name='user[email]']"
  end

  test "the forgot password page renders outside the application navbar" do
    get new_user_password_path

    assert_select "nav.navbar-light", false
  end

  test "the reset password page renders the new password fields" do
    get edit_user_password_path(reset_password_token: "a-token")

    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "the reset password page renders outside the application navbar" do
    get edit_user_password_path(reset_password_token: "a-token")

    assert_select "nav.navbar-light", false
  end

  test "the forgot password page labels its input" do
    get new_user_password_path

    assert_select "label[for='user_email']"
  end

  test "the reset password page labels every input" do
    get edit_user_password_path(reset_password_token: "a-token")

    assert_select "label[for='user_password']"
    assert_select "label[for='user_password_confirmation']"
  end
end
