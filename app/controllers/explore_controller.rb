class ExploreController < ApplicationController
  before_action :authenticate_user!
  before_action :load_trending_hashtags, if: :render_aside?

  def index
    @posts = Post.discoverable_for(current_user)
                 .includes(image_attachment: :blob)
                 .page(params[:page]).per(12)
  end

  private

  def load_trending_hashtags
    @hashtags = HashTag.trending.limit(6)
  end
end
