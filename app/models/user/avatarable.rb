# frozen_string_literal: true

module User::Avatarable
  extend ActiveSupport::Concern

  included do
    has_one_attached :avatar do |attachable|
      attachable.variant :thumb, resize_to_fill: [ 112, 112 ], preprocessed: true
      attachable.variant :large, resize_to_fill: [ 280, 280 ], preprocessed: true
    end

    validates :avatar, image: true
  end
end
