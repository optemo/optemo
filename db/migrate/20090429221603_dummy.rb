class Dummy < ActiveRecord::Migration
  def self.up
    add_column :retailer_offerings, :condition, :string, :default => "New"
  end

  def self.down
    #remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
