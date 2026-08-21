class PostMailer < ApplicationMailer
  def published_post(post)
    @post = post
    mail(to: @post.user.email, subject: "Your post was published!")
  end
end
