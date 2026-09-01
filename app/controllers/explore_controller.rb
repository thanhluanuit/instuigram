class ExploreController < ApplicationController
  before_action :authenticate_user!

  def index
    @posts = Post.discoverable_for(current_user)
                 .includes(image_attachment: :blob)
                 .page(params[:page]).per(12)
  end
end
