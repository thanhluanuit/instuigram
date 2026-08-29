require "test_helper"

class Api::JwtAuthenticatableTest < ActiveSupport::TestCase
  test "uses the credential when it is present" do
    assert_equal "a-credential-key", Api::JwtAuthenticatable.secret_key("a-credential-key")
  end

  test "raises rather than falling back outside development and test" do
    error = assert_raises(Api::JwtAuthenticatable::MissingSecretKey) do
      Api::JwtAuthenticatable.secret_key(nil, env: env("production"))
    end

    assert_match "required in production", error.message
  end

  test "raises for a blank credential too" do
    assert_raises(Api::JwtAuthenticatable::MissingSecretKey) do
      Api::JwtAuthenticatable.secret_key("", env: env("staging"))
    end
  end

  test "derives a stable key in development and test when the credential is missing" do
    key = Api::JwtAuthenticatable.secret_key(nil, env: env("test"))

    assert_not_nil key
    assert_not_equal Rails.application.secret_key_base, key
    assert_equal key, Api::JwtAuthenticatable.secret_key(nil, env: env("development"))
  end

  private

  def env(name)
    ActiveSupport::EnvironmentInquirer.new(name)
  end
end
