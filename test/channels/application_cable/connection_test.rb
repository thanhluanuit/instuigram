require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "identifies the current_user from the Warden session" do
      connect env: { "warden" => Struct.new(:user).new(users(:one)) }

      assert_equal users(:one), connection.current_user
    end

    test "sets current_user to nil when Warden has no authenticated user" do
      connect env: { "warden" => Struct.new(:user).new(nil) }

      assert_nil connection.current_user
    end
  end
end
