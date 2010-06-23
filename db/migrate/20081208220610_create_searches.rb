class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.primary_key :id
      t.integer :session_id
      t.integer :parent_id
      t.integer :layer
      t.string :c0,:c1,:c2,:c3,:c4,:c5,:c6,:c7,:c8
      t.string :desc
      t.integer :cluster_count
      t.integer :result_count
      t.string :brand, :default => "All Brands"
      t.float :price_min, :default => 0
      t.float :price_max, :default => 10000000
      t.text :searchpids
      t.string :searchterm
      t.integer :page
      t.string :view
      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
