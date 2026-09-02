class AddKeyToKeyables < ActiveRecord::Migration[8.1]
  TABLES = %i[posts users comments conversations messages].freeze

  def up
    TABLES.each do |table|
      add_column table, :key, :uuid, default: -> { "gen_random_uuid()" }

      execute <<~SQL
        UPDATE #{quote_table_name(table)}
        SET key = gen_random_uuid()
        WHERE key IS NULL
      SQL
    end
  end

  def down
    TABLES.each { |table| remove_column table, :key }
  end
end
