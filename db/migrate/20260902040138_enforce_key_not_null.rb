class EnforceKeyNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :posts, :key, false
    change_column_null :users, :key, false
    change_column_null :comments, :key, false
    change_column_null :conversations, :key, false
    change_column_null :messages, :key, false
  end
end
