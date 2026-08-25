class AddCommentsCountToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :comments_count, :integer, null: false, default: 0

    execute <<~SQL.squish
      UPDATE posts
      SET comments_count = comment_counts.count
      FROM (SELECT post_id, COUNT(*) AS count FROM comments GROUP BY post_id) AS comment_counts
      WHERE posts.id = comment_counts.post_id
    SQL
  end

  def down
    remove_column :posts, :comments_count
  end
end
