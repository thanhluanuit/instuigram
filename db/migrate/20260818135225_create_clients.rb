class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :user, null: false, foreign_key: true
      t.string :client_id, null: false
      t.string :client_secret_digest, null: false

      t.timestamps
    end
    add_index :clients, :client_id, unique: true
  end
end
