class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def update
  end
end
