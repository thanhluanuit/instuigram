class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }, index: false
      t.references :followed, null: false, foreign_key: { to_table: :users }, index: false

      t.timestamps
    end

    add_index :follows, [ :follower_id, :followed_id ], unique: true
    add_index :follows, :followed_id

    add_check_constraint :follows, "follower_id <> followed_id", name: "follows_no_self_follow"
  end
end
