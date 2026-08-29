# frozen_string_literal: true

require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  test "the sign in page renders the email and password fields" do
    get new_user_session_path

    assert_select "input[name='user[email]']"
    assert_select "input[name='user[password]']"
  end

  test "the sign in page renders outside the application navbar" do
    get new_user_session_path

    assert_select "nav.navbar", false
  end

  test "the sign in page links to sign up and to password recovery" do
    get new_user_session_path

    assert_select "a[href=?]", new_user_registration_path
    assert_select "a[href=?]", new_user_password_path
  end

  test "the sign in page labels every input" do
    get new_user_session_path

    assert_select "label[for='user_email']"
    assert_select "label[for='user_password']"
  end
end
