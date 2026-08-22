require "test_helper"

class Posts::CreateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "creates a post owned by the given user" do
    post = Posts::Create.call(user: @user, post_params: valid_post_params)

    assert post.persisted?
    assert_equal @user, post.user
  end

  test "enqueues a published_post email when the post is created" do
    post = Posts::Create.call(user: @user, post_params: valid_post_params)

    assert_enqueued_email_with(PostMailer, :published_post, args: [ post ])
  end

  test "when the image is missing, returns a non-persisted post and enqueues no email" do
    assert_no_enqueued_emails do
      post = Posts::Create.call(user: @user, post_params: { description: "no image attached" })

      assert_not post.persisted?
    end
  end

  private

  def valid_post_params(description: "hello #world")
    {
      description: description,
      image:       {
        io:           File.open(Rails.root.join("test/fixtures/files/test_image.png")),
        filename:     "test_image.png",
        content_type: "image/png"
      }
    }
  end
end
