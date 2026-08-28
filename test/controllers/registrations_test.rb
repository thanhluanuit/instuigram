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

    assert_select "nav.navbar-light", false
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
end
