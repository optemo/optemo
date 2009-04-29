class Dummy < ActiveRecord::Migration
  def self.up
  end

  def self.down
    #remove_column :cameras, :availability
    #remove_column :printers, :availability
  end
end
