class HomeController < ApplicationController
  def index
    @posts = current_user.posts.order(created_at: :desc)
  end
end
