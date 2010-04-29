class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.primary_key :id
      t.string :product_type
      t.string :title
      t.string :model
      t.string :mpn
      t.boolean :instock
      t.string :imagesurl
      t.integer :imagesh
      t.integer :imagesw
      t.string :imagemurl
      t.integer :imagemh
      t.integer :imagemw
      t.string :imagelurl
      t.integer :imagelh
      t.integer :imagelw
      t.float :avgreviewrating
      t.integer :totalreviews

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
