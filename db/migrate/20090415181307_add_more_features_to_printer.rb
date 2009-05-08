class AddMoreFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :pricehistory, :string
    add_column :printers, :bestoffer, :integer
    add_column :cameras, :pricehistory, :string
    add_column :cameras, :bestoffer, :integer
  end

  def self.down
    remove_column :printers, :pricehistory
    remove_column :printers, :bestoffer
    remove_column :cameras, :pricehistory
    remove_column :cameras, :bestoffer
  end
end
