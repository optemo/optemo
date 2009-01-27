class AddTooLowToPrinter < ActiveRecord::Migration
  def self.up
    add_column :printers, :toolow, :boolean
  end

  def self.down
    remove_column :printers, :toolow
  end
end
