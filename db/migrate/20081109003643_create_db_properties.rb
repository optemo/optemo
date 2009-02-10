class CreateDbProperties < ActiveRecord::Migration
  def self.up
    create_table :db_properties do |t|
      t.primary_key :id
      t.string :product
      t.text  :brands
      t.float :price_min
      t.float :price_max
      
      t.timestamps
    end
  end

  def self.down
    drop_table :db_properties
  end
end
