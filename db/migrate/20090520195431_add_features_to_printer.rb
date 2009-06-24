class AddFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    #add_column :printers, :resolutionmax, :integer
    add_column :printers, :fax, :boolean
    add_column :printers, :bw, :boolean
  end

  def self.down
  end
end
