class AddRealFeaturesToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :ppm, :integer
    add_column :printers, :ttp, :integer
    add_column :printers, :resolution, :string
  end

  def self.down
  end
end
