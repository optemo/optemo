class Dummy < ActiveRecord::Migration
  def self.up
    add_column :cartridges, :instock_ca, :boolean#, :default => "New"
  end

  def self.down
    #remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
