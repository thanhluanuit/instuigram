require "test_helper"

class SubscriptionAdapterTest < ActiveSupport::TestCase
  test "the redis pubsub adapter development and production use loads under the bundled redis gem" do
    assert_nothing_raised do
      require "action_cable/subscription_adapter/redis"
    end
  end
end
