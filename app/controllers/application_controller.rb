class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def log_event(event_type:, subject:)
    current_user.event_logs.create!(
      event_type: event_type,
      subject: subject,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
