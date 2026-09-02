# frozen_string_literal: true

module Keyable
  extend ActiveSupport::Concern

  included do
    before_create :assign_key
  end

  private

  def assign_key
    self.key = SecureRandom.uuid
  end
end
