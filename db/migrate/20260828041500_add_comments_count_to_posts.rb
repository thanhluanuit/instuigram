class AddCommentsCountToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :comments_count, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE posts
      SET comments_count = (SELECT COUNT(*) FROM comments WHERE comments.post_id = posts.id)
    SQL
  end

  def down
    remove_column :posts, :comments_count
  end
end
