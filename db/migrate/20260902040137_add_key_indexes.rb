class AddKeyIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TABLES = %i[posts users comments conversations messages].freeze

  def change
    TABLES.each { |table| add_index table, :key, unique: true, algorithm: :concurrently }
  end
end
