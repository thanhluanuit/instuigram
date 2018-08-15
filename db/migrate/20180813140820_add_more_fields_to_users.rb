class AddMoreFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :username, :string
    add_column :users, :name, :string
    add_column :users, :website, :string
    add_column :users, :bio, :text
    add_column :users, :phone, :integer
    add_column :users, :gender, :string
  end
end
