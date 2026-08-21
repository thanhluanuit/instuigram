require "test_helper"

class PostMailerTest < ActionMailer::TestCase
  test "published_post sends to the post's owner with the post's description" do
    post = create_post!(users(:one), description: "hello #world")

    email = PostMailer.published_post(post)

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [ users(:one).email ], email.to
    assert_equal [ "from@example.com" ], email.from
    assert_equal "Your post was published!", email.subject
    assert_match "hello #world", email.text_part.body.to_s
    assert_match "hello #world", email.html_part.body.to_s
  end
end
