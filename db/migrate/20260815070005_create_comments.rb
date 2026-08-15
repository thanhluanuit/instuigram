class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.belongs_to :post, null: false
      t.belongs_to :user, null: false, index: false
      t.text :body, null: false
      t.integer :reactions_count, null: false, default: 0

      t.timestamps
    end
  end
end
