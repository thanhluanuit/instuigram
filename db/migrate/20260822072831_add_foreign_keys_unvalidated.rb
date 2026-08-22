class AddForeignKeysUnvalidated < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :posts, :users, validate: false
    add_foreign_key :comments, :users, validate: false
    add_foreign_key :comments, :posts, validate: false
    add_foreign_key :post_hash_tags, :posts, validate: false
    add_foreign_key :post_hash_tags, :hash_tags, validate: false
    add_foreign_key :reactions, :users, validate: false
  end
end
