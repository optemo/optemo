class ProductMediumSmallImage < ActiveRecord::Migration
  def self.up
    add_column :products, :imgmsurl, :string
    add_column :products, :imgmsh, :integer
    add_column :products, :imgmsw, :integer
  end

  def self.down
    remove_column :products, :small_title
    remove_column :products, :imgmsh
    remove_column :products, :imgmsw
  end
end
