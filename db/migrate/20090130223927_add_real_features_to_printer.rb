class AddRealFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :ppm, :float
    add_column :printers, :ttp, :float
    add_column :printers, :resolution, :string
  end

  def self.down
    remove_column :printers, :ppm
    remove_column :printers, :ttp
    remove_column :printers, :resolution
  end
end
