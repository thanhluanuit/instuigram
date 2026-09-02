require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "bcrypt"

module ActiveStorageTestHelper
  def attach_test_image(attachable)
    attachable.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
      filename: "test_image.png",
      content_type: "image/png"
    )
  end

  def attach_non_image_file(attachable)
    attachable.attach(
      io: StringIO.new("just some text, not an image"),
      filename: "not_an_image.txt",
      content_type: "text/plain"
    )
  end

  def attach_oversized_image(attachable)
    png_signature = "\x89PNG\r\n\x1a\n".b
    attachable.attach(
      io: StringIO.new(png_signature + ("a" * 11.megabytes)),
      filename: "too_big.png",
      content_type: "image/png"
    )
  end
end

module UserTestHelper
  def build_user(email: "new_user@example.com", password: "password123", website: nil)
    User.new(email: email, password: password, username: "new_user", website: website)
  end
end

module PostTestHelper
  def build_post(user, description: "hello world", attach_image: true)
    post = Post.new(user: user, description: description)
    attach_test_image(post.image) if attach_image
    post
  end

  def create_post!(user, description:)
    post = user.posts.new(description: description)
    attach_test_image(post.image)
    post.save!
    post
  end

  def attach_images_to_all_posts!
    Post.find_each { |post| attach_test_image(post.image) }
  end

  def index_all_posts!
    Post.__elasticsearch__.create_index!(force: true)
    Post.find_each { |post| post.__elasticsearch__.index_document }
    Post.__elasticsearch__.refresh_index!
  end

  def index_pending_posts!
    perform_enqueued_jobs
    Post.__elasticsearch__.refresh_index!
  end
end

module TurboStreamTestHelper
  def follow_state_stream(user)
    Turbo::StreamsChannel.send(:stream_name_from, [ user, :follow_state ])
  end
end

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  parallelize_setup do |worker|
    ENV["ELASTICSEARCH_TEST_WORKER_NUMBER"] = worker.to_s
    Post.__elasticsearch__.create_index!(force: true)
  end
  fixtures :all
  include ActiveStorageTestHelper
  include UserTestHelper
  include PostTestHelper
  include TurboStreamTestHelper
  include ActionCable::TestHelper
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
