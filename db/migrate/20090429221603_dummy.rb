class Dummy < ActiveRecord::Migration
  def self.up
    add_column :amazon_cartridges, :numberofitems, :integer#, :default => "New"
    add_column :amazon_cartridges, :specialfeatures, :text#, :default => "New"
  end

  def self.down
    #remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
