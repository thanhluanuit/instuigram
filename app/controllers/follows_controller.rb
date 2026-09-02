class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    return redirect_to profile_path, alert: "You cannot follow yourself." if @user == current_user

    follow = Follows::Create.call(follower: current_user, followed: @user)
    log_event(event_type: :follow_created, subject: follow) if follow.previously_new_record?

    render_follow_state
  end

  def destroy
    Follows::Destroy.call(follower: current_user, followed: @user)

    render_follow_state
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def render_follow_state
    respond_to do |format|
      format.turbo_stream { render :create }
      format.html { redirect_back fallback_location: user_path(@user) }
    end
  end
end
