class CreateCompatibilities < ActiveRecord::Migration
  def self.up
    create_table :compatibilities do |t|

      t.timestamps
      
      t.integer :accessory_id
      t.string  :accessory_type
      t.integer :product_id
      t.string  :product_type
      
    end
  end

  def self.down
    drop_table :compatibilities
  end
end
