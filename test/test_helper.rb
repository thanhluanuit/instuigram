require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'bcrypt'

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
