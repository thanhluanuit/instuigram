class AddIndexOnCreatedAtToPosts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :posts, :created_at, order: { created_at: :desc }, algorithm: :concurrently
  end
end
