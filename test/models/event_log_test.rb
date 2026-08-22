require "test_helper"

class EventLogTest < ActiveSupport::TestCase
  test "supports the five tracked event types" do
    assert_equal %w[post_created post_destroyed profile_updated comment_created reaction_created],
                 EventLog::EVENT_TYPES.values
  end

  test "is invalid without a user" do
    event_log = build_event_log(user: nil)

    assert_not event_log.valid?
    assert_includes event_log.errors[:user], "must exist"
  end

  test "is invalid without a subject" do
    event_log = build_event_log(subject: nil)

    assert_not event_log.valid?
    assert_includes event_log.errors[:subject], "must exist"
  end

  private

  def build_event_log(user: users(:one), subject: posts(:one), event_type: :post_created)
    EventLog.new(user: user, subject: subject, event_type: event_type,
                 ip_address: "127.0.0.1", user_agent: "Rails Testing")
  end
end
