class AddFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :resolutionarea, :integer
  end

  def self.down
  end
end
