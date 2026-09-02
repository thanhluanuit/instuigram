class EnforceKeyNotNull < ActiveRecord::Migration[8.1]
  TABLES = %i[posts users comments conversations messages].freeze

  def change
    TABLES.each { |table| change_column_null table, :key, false }
  end
end
