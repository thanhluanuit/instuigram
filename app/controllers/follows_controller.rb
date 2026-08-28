class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    return redirect_to user_path(@user), alert: "You cannot follow yourself." if @user == current_user

    follow = Follows::Create.call(follower: current_user, followed: @user)
    log_event(event_type: :follow_created, subject: follow) if follow.previously_new_record?

    redirect_to user_path(@user)
  end

  def destroy
    Follows::Destroy.call(follower: current_user, followed: @user)

    redirect_to user_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
