# frozen_string_literal: true

module Post::Imageable
  extend ActiveSupport::Concern

  included do
    has_one_attached :image do |attachable|
      attachable.variant :feed, resize_to_fill: [ 1200, 1200 ], quality: 100, strip: true
      attachable.variant :detail, resize_to_limit: [ 1600, 1600 ], quality: 100, strip: true
      attachable.variant :thumb, resize_to_fill: [ 600, 600 ], quality: 100, strip: true
    end

    validates :image, image: { required: true }
  end
end
