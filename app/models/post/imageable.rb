# frozen_string_literal: true

module Post::Imageable
  extend ActiveSupport::Concern

  included do
    has_one_attached :image do |attachable|
      attachable.variant :feed, resize_to_limit: [ 600, 600 ]
      attachable.variant :detail, resize_to_limit: [ 1200, 1200 ]
      attachable.variant :thumb, resize_to_fill: [ 440, 440 ]
    end

    validates :image, image: { required: true }
  end
end
