class ProductMediumSmallImage < ActiveRecord::Migration
  def self.up
    add_column :products, :imgmsurl, :string
    add_column :products, :imgmsh, :integer
    add_column :products, :imgmsw, :integer
    add_column :products, :imggburl, :string
    add_column :products, :imggbh, :integer
    add_column :products, :imggbw, :integer
  end

  def self.down
    remove_column :products, :imgmsurl
    remove_column :products, :imgmsh
    remove_column :products, :imgmsw
    remove_column :products, :imggburl
    remove_column :products, :imggbh
    remove_column :products, :imggbw
  end
end
