require "test_helper"

class LogEventJobTest < ActiveSupport::TestCase
  test "creates an EventLog with the given attributes" do
    user = users(:one)
    post = posts(:one)

    assert_difference("EventLog.count", 1) do
      perform_job(user: user, event_type: "post_created", subject_type: "Post", subject_id: post.id)
    end

    event_log = EventLog.last
    assert_equal user, event_log.user
    assert_equal "post_created", event_log.event_type
    assert_equal "Post", event_log.subject_type
    assert_equal post.id, event_log.subject_id
    assert_equal "127.0.0.1", event_log.ip_address.to_s
    assert_equal "Rails Testing", event_log.user_agent
  end

  test "creates an EventLog even when the subject no longer exists" do
    post = posts(:one)
    subject_id = post.id
    post.destroy

    assert_difference("EventLog.count", 1) do
      perform_job(user: users(:one), event_type: "post_destroyed", subject_type: "Post", subject_id: subject_id)
    end
  end

  private

  def perform_job(user:, event_type:, subject_type:, subject_id:)
    LogEventJob.perform_now(
      user_id: user.id,
      event_type: event_type,
      subject_type: subject_type,
      subject_id: subject_id,
      ip_address: "127.0.0.1",
      user_agent: "Rails Testing"
    )
  end
end
