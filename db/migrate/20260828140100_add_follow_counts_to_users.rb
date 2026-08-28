class AddFollowCountsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :followers_count, :integer, null: false, default: 0
    add_column :users, :following_count, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE users
      SET followers_count = (SELECT COUNT(*) FROM follows WHERE follows.followed_id = users.id),
          following_count = (SELECT COUNT(*) FROM follows WHERE follows.follower_id = users.id)
    SQL
  end

  def down
    remove_column :users, :followers_count
    remove_column :users, :following_count
  end
end
