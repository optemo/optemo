class CreateAmazonGroups < ActiveRecord::Migration
  def self.up
    create_table :amazon_groups do |t|

      t.timestamps
      t.primary_key :id
      t.boolean :processed, :default => false
      t.string :url              
      t.string :brand       
      t.string :megapixels_range
      t.string :opticalZoom_range  
      t.string :displaySize_range      
      t.string :imageStabilization
      t.string :viewfinderType  
      t.boolean :leaf, :default => false
      t.datetime :scrapedAt
    end
  end

  def self.down
    drop_table :amazon_groups
  end
end
