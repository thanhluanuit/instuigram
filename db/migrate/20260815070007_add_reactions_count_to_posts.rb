class AddReactionsCountToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :reactions_count, :integer, null: false, default: 0
  end
end
