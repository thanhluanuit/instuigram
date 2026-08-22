class CreateEventLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :event_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.references :subject, polymorphic: true, null: false
      t.inet :ip_address, null: false
      t.string :user_agent
      t.timestamps
    end
  end
end
