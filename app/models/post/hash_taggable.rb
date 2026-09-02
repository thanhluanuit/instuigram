# frozen_string_literal: true

module Post::HashTaggable
  extend ActiveSupport::Concern

  HASH_TAG_PATTERN = /#(\w+)/

  included do
    has_many :post_hash_tags, dependent: :destroy
    has_many :hash_tags, through: :post_hash_tags

    after_commit :create_hash_tags, on: :create
  end

  private

  def create_hash_tags
    extracted_hash_tag_names.each do |name|
      hash_tags << HashTag.find_or_create_by(name: name)
    end
  end

  def extracted_hash_tag_names
    description.to_s.scan(HASH_TAG_PATTERN).flatten.uniq
  end
end
