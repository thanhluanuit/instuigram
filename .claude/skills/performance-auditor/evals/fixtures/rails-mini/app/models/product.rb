class Product < ApplicationRecord
  belongs_to :category
  has_many :reviews

  # CLEAN: correctly indexed filter (products.status is indexed in structure.sql).
  # A missing-index finding here is a false positive — this is eval 2b's trap.
  scope :active, -> { where(status: "active") }

  # PLANT: loads every row into memory to count them.
  def self.active_count
    Product.all.select { |p| p.status == "active" }.length
  end

  # PLANT: instantiates full AR objects to read one column.
  def self.active_names
    Product.where(status: "active").map(&:name)
  end
end
