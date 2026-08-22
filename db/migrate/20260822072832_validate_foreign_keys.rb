class ValidateForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :posts, :users
    validate_foreign_key :comments, :users
    validate_foreign_key :comments, :posts
    validate_foreign_key :post_hash_tags, :posts
    validate_foreign_key :post_hash_tags, :hash_tags
    validate_foreign_key :reactions, :users
  end
end
