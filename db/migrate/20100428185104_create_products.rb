class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.primary_key :id
      t.string :product_type
      t.string :title
      t.string :model
      t.string :mpn
      t.boolean :instock
      t.string :imgsurl
      t.integer :imgsh
      t.integer :imgsw
      t.string :imgmurl
      t.integer :imgmh
      t.integer :imgmw
      t.string :imglurl
      t.integer :imglh
      t.integer :imglw
      t.float :avgreviewrating
      t.integer :totalreviews
      t.string :manufacturerurl

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
