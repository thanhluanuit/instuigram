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

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
  include ActiveStorageTestHelper
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
