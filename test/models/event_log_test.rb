require "test_helper"

class EventLogTest < ActiveSupport::TestCase
  test "supports the seven tracked event types" do
    assert_equal %w[post_created post_destroyed profile_updated comment_created reaction_created message_sent
                    follow_created],
                 EventLog::EVENT_TYPES.values
  end

  test "is invalid without a user" do
    event_log = build_event_log(user: nil)

    assert_not event_log.valid?
    assert_includes event_log.errors[:user], "must exist"
  end

  test "is invalid without a subject_type" do
    event_log = build_event_log(subject_type: nil)

    assert_not event_log.valid?
    assert_includes event_log.errors[:subject_type], "can't be blank"
  end

  test "is invalid without a subject_id" do
    event_log = build_event_log(subject_id: nil)

    assert_not event_log.valid?
    assert_includes event_log.errors[:subject_id], "can't be blank"
  end

  test "is valid when the subject record no longer exists" do
    post = posts(:one)
    subject_id = post.id
    post.destroy

    assert build_event_log(subject_type: "Post", subject_id: subject_id).valid?
  end

  private

  def build_event_log(user: users(:one), subject_type: "Post", subject_id: posts(:one).id, event_type: :post_created)
    EventLog.new(user: user, subject_type: subject_type, subject_id: subject_id, event_type: event_type,
                 ip_address: "127.0.0.1", user_agent: "Rails Testing")
  end
end
