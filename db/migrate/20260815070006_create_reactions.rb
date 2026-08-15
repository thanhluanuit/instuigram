class CreateReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :reactions do |t|
      t.belongs_to :user, null: false, index: false
      t.belongs_to :reactable, polymorphic: true, null: false, index: true
      t.string :reaction_type, null: false, default: "like"

      t.timestamps
    end

    add_index :reactions, [ :user_id, :reactable_type, :reactable_id ], unique: true
  end
end
