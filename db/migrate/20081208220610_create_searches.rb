class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.string :brand
      t.integer :session_id
      t.float :maximumresolution_min, :default => 0
      t.float :maximumresolution_max, :default => 10 
      t.float :opticalzoom_min, :default => 0 
      t.float :opticalzoom_max, :default => 8 
      t.float :displaysize_min, :default => 0 
      t.float :displaysize_max, :default => 7 
      t.float :price_min, :default => 0
      t.float :price_max, :default => 5000 

      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
