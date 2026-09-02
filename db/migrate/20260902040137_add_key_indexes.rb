class AddKeyIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :posts, :key, unique: true, algorithm: :concurrently
    add_index :users, :key, unique: true, algorithm: :concurrently
    add_index :comments, :key, unique: true, algorithm: :concurrently
    add_index :conversations, :key, unique: true, algorithm: :concurrently
    add_index :messages, :key, unique: true, algorithm: :concurrently
  end
end
