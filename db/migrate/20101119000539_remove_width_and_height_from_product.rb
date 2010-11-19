class RemoveWidthAndHeightFromProduct < ActiveRecord::Migration
  def self.up
    remove_column :products, :imgmsh
    remove_column :products, :imgmsw
    remove_column :products, :imgsh
    remove_column :products, :imgsw
    remove_column :products, :imglh
    remove_column :products, :imglw
    remove_column :products, :imgmh
    remove_column :products, :imgmw
    remove_column :products, :imggbh
    remove_column :products, :imggbw
  end

  def self.down
    add_column :products, :imgmsh, :integer
    add_column :products, :imgmsh, :integer
    add_column :products, :imgmsw, :integer
    add_column :products, :imgsh, :integer
    add_column :products, :imgsw, :integer
    add_column :products, :imglh, :integer
    add_column :products, :imglw, :integer
    add_column :products, :imgmh, :integer
    add_column :products, :imgmw, :integer
    add_column :products, :imggbh, :integer
    add_column :products, :imggbw, :integer
  end
end
