class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  layout :layout_by_resource

  helper_method :render_aside?

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :load_aside_suggestions, if: :render_aside?

  private

  def render_aside?
    user_signed_in? && request.get? && request.format.symbol == :html && !turbo_frame_request?
  end

  def load_aside_suggestions
    @aside_suggestions = User.suggested_for(current_user)
                             .includes(avatar_attachment: :blob)
                             .limit(3)
                             .load
  end

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
