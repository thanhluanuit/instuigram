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
end

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
  include ActiveStorageTestHelper
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
