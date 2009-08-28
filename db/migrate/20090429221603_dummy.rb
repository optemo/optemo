class Dummy < ActiveRecord::Migration
  def self.up
    add_column :cartridges, :instock_ca, :boolean#, :default => "New"
    add_column :cartridges, :price_ca, :integer#, :default => "New"
    add_column :cartridges, :price_ca_str, :string#, :default => "New"
    #"price_ca", "price_ca_str", "instock_ca"
  end

  def self.down
    #remove_column :newegg_offerings, :url
    #remove_column :printers, :availability
  end
end
