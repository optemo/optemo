class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.primary_key :id
      t.integer :session_id
      t.integer :parent_id
      t.integer :cluster_id
      t.integer :product_id
      t.integer :filter
      t.string :brand, :default => "All Brands"
      DbFeature.find(:all).each do |f|
        min = f.name+'_min'
        max = f.name+'_max'
        t.float min.intern, :default => f.min
        t.float max.intern, :default => f.max
      end
      t.float :price_min, :default => 0
      t.float :price_max, :default => 10000000
      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
