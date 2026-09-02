require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActionView::RecordIdentifier

  driven_by :selenium, using: ENV["HEADED"].present? ? :chrome : :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--disable-features=PasswordLeakDetection")
    options.add_preference("profile.password_manager_leak_detection", false)
    options.add_preference("profile.password_manager_enabled", false)
    options.add_preference("credentials_enable_service", false)
  end

  Capybara.default_max_wait_time = 10

  def sign_in_as(user, password: "password123")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Log in"

    assert_current_path root_path
  end

  def browser_readable_fixture_file(filename)
    path = File.join(Dir.tmpdir, "instuigram_system_test_#{filename}")
    FileUtils.cp(file_fixture(filename), path)
    path
  end

  def wait_for_page_to_settle
    wait_for_script "window.Turbo !== undefined && window.Turbo.session.started"
    wait_for_script "window.Stimulus !== undefined"
    wait_for_script <<~JS
      Array.from(document.images)
        .filter((image) => image.currentSrc !== "")
        .every((image) => image.complete)
    JS
  end

  def wait_for_cable(identifier)
    wait_for_script <<~JS
      (() => {
        const element = document.querySelector('[data-controller~="#{identifier}"]')
        if (!element) return false
        const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "#{identifier}")
        if (!controller || !controller.subscription) return false
        return controller.subscription.consumer.subscriptions.guarantor.pendingSubscriptions.length === 0
      })()
    JS
  end

  def assert_no_navigation
    page.execute_script("document.body.dataset.navigationMark = 'kept'")

    yield

    assert_selector "body[data-navigation-mark='kept']", visible: :all
  end

  def within_session_as(name, user)
    using_session(name) do
      sign_in_as(user)
      yield
    end
  end

  private

  def wait_for_script(condition)
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until page.evaluate_script(condition)
    end
  end
end
