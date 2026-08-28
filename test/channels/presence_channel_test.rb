require "test_helper"

class PresenceChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams presence for a signed-in user" do
    stub_connection(current_user: users(:one))
    subscribe

    assert subscription.confirmed?
    assert_has_stream "presence"
  end

  test "rejects the subscription when the connection is anonymous" do
    stub_connection(current_user: nil)
    subscribe

    assert subscription.rejected?
  end

  test "subscribing records that the user was just seen" do
    assert_nil users(:one).last_seen_at

    stub_connection(current_user: users(:one))
    subscribe

    assert_not_nil users(:one).reload.last_seen_at
  end

  test "announces the user coming online" do
    stub_connection(current_user: users(:one))

    assert_broadcasts("presence", 1) { subscribe }
  end

  test "does not announce again for a user already seen as online" do
    users(:one).update_column(:last_seen_at, 10.seconds.ago)
    stub_connection(current_user: users(:one))

    assert_no_broadcasts("presence") { subscribe }
  end

  test "unsubscribing records the moment the user was last seen" do
    stub_connection(current_user: users(:one))
    subscribe

    unsubscribe

    assert_not_nil users(:one).reload.last_seen_at
  end
end
