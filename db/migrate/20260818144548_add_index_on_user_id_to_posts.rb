class AddIndexOnUserIdToPosts < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :posts, :user_id, algorithm: :concurrently
  end
end
