class AddMoreFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :oldprices, :string
  end

  def self.down
    remove_column :printers, :oldprices
  end
end
