class CreateRetailers < ActiveRecord::Migration
  def self.up
    create_table :retailers do |t|
      t.string :url
      t.string :name
      t.string :image
      

      t.timestamps
    end
  end

  def self.down
    drop_table :retailers
  end
end
