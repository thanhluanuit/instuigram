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
    extracted_hash_tag_names.each { |name| hash_tags << hash_tag_named(name) }
  end

  def hash_tag_named(name)
    HashTag.find_by(name: name) || HashTag.create_or_find_by(name: name)
  end

  def extracted_hash_tag_names
    description.to_s.scan(HASH_TAG_PATTERN).flatten.uniq
  end
end
