class LogEventJob < ApplicationJob
  queue_as :default

  def perform(user_id:, event_type:, subject_type:, subject_id:, ip_address:, user_agent:)
    EventLog.create!(
      user_id: user_id,
      event_type: event_type,
      subject_type: subject_type,
      subject_id: subject_id,
      ip_address: ip_address,
      user_agent: user_agent
    )
  end
end
