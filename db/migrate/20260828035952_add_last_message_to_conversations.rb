class AddLastMessageToConversations < ActiveRecord::Migration[8.1]
  def change
    add_reference :conversations, :last_message,
                  foreign_key: { to_table: :messages, on_delete: :nullify }
  end
end
