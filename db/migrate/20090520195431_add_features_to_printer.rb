class AddFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :resolutionmax, :integer
  end

  def self.down
  end
end
