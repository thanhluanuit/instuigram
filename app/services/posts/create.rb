# frozen_string_literal: true

class Posts::Create < BaseService
  def initialize(user:, post_params:)
    @user        = user
    @post_params = post_params
  end

  def call
    post = user.posts.create(post_params)
    send_email_notification(post)
    post
  end

  private

  attr_reader :user, :post_params

  def send_email_notification(post)
    PostMailer.published_post(post).deliver_later if post.persisted?
  end
end
