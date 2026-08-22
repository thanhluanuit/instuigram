class AddIntegrityIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :comments, :user_id, algorithm: :concurrently
    add_index :post_hash_tags, [ :post_id, :hash_tag_id ], unique: true, algorithm: :concurrently
    remove_index :post_hash_tags, :post_id, algorithm: :concurrently
    add_index :hash_tags, :name, unique: true, algorithm: :concurrently
  end
end
