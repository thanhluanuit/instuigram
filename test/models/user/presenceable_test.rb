require "test_helper"

class User::PresenceableTest < ActiveSupport::TestCase
  test "online? is true when last seen within the last minute" do
    users(:one).update_column(:last_seen_at, 30.seconds.ago)

    assert_predicate users(:one).reload, :online?
  end

  test "online? is false when last seen more than a minute ago" do
    users(:one).update_column(:last_seen_at, 2.minutes.ago)

    assert_not users(:one).reload.online?
  end

  test "online? is false when the user has never been seen" do
    assert_not users(:one).online?
  end
end
