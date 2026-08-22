class EnforceNotNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :posts, :user_id, false
    change_column_null :comments, :user_id, false
    change_column_null :post_hash_tags, :post_id, false
    change_column_null :post_hash_tags, :hash_tag_id, false
    change_column_null :hash_tags, :name, false
  end
end
