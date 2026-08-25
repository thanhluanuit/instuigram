class HomeController < ApplicationController
  before_action :authenticate_user!
  def index
    @posts              = feed_posts
    @user_reactions     = current_user.reactions.where(reactable: @posts).index_by(&:reactable_id)
    @trending_hash_tags = trending_hash_tags
    @suggested_users    = suggested_users
  end

  private

  def feed_posts
    Post.includes(user: { avatar_attachment: :blob }, image_attachment: :blob)
        .order(created_at: :desc)
        .page(params[:page])
        .per(10)
  end

  def trending_hash_tags
    Rails.cache.fetch("home:trending_hash_tags", expires_in: 15.minutes) do
      HashTag.trending.to_a
    end
  end

  def suggested_users
    Rails.cache.fetch("home:suggested_users:#{current_user.id}", expires_in: sidebar_cache_ttl) do
      User.suggested_for(current_user).to_a
    end
  end

  def sidebar_cache_ttl
    15.minutes
  end
end
