class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def log_event(event_type:, subject:)
    LogEventJob.perform_later(
      user_id: current_user.id,
      event_type: event_type,
      subject_type: subject.class.name,
      subject_id: subject.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
