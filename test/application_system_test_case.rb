require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--disable-features=PasswordLeakDetection")
    options.add_preference("profile.password_manager_leak_detection", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("credentials_enable_service", false)
  end

  def sign_in_as(user, password: "password123")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Log in"

    assert_current_path root_path
  end
end
