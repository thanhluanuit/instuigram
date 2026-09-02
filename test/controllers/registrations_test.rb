# frozen_string_literal: true

require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  test "signing up persists the submitted username" do
    post user_registration_path, params: { user: sign_up_params }

    assert_equal "newcomer", User.find_by(email: "newcomer@instuigram.com").username
  end

  test "signing up persists the submitted name" do
    post user_registration_path, params: { user: sign_up_params }

    assert_equal "New Comer", User.find_by(email: "newcomer@instuigram.com").name
  end

  test "the sign up page renders the username and name fields" do
    get new_user_registration_path

    assert_select "input[name='user[username]']"
    assert_select "input[name='user[name]']"
  end

  test "the sign up page renders outside the application navbar" do
    get new_user_registration_path

    assert_select "nav.navbar", false
  end

  test "the change password page renders the password fields" do
    sign_in users(:one)

    get edit_user_registration_path

    assert_select "input[name='user[current_password]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "the change password page omits the profile fields owned by the profile form" do
    sign_in users(:one)

    get edit_user_registration_path

    assert_select "input[name='user[email]']", false
  end

  test "the change password page keeps the application navbar" do
    sign_in users(:one)

    get edit_user_registration_path

    assert_select "nav.navbar"
  end

  test "the change password page marks Profile current in the navigation rail" do
    sign_in users(:one)

    get edit_user_registration_path

    assert_select "nav.app-rail a.is-active[aria-current=?]", "page", text: /Profile/
  end

  test "a rejected password change keeps Profile marked current in the navigation rail" do
    sign_in users(:one)

    put user_registration_path, params: { user: {
      current_password: "wrong-password",
      password: "brand-new-password",
      password_confirmation: "brand-new-password"
    } }

    assert_select "nav.app-rail a.is-active[aria-current=?]", "page", text: /Profile/
  end

  test "a wrong current password leaves the password unchanged" do
    user = users(:one)
    sign_in user

    put user_registration_path, params: { user: {
      current_password: "wrong-password",
      password: "brand-new-password",
      password_confirmation: "brand-new-password"
    } }

    assert user.reload.valid_password?("password123")
  end

  private

  def sign_up_params
    {
      email: "newcomer@instuigram.com",
      name: "New Comer",
      username: "newcomer",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  test "the sign up page labels every input" do
    get new_user_registration_path

    assert_select "label[for='user_email']"
    assert_select "label[for='user_name']"
    assert_select "label[for='user_username']"
    assert_select "label[for='user_password']"
    assert_select "label[for='user_password_confirmation']"
  end
end
