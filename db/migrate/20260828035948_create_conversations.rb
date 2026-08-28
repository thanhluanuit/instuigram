class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :participants_key, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, :participants_key, unique: true
  end
end
