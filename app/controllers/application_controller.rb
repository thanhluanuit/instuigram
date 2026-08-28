class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  layout :layout_by_resource

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def layout_by_resource
    devise_controller? && !user_signed_in? ? "auth" : "application"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name username])
  end

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
