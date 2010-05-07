class CreateClusters < ActiveRecord::Migration
  def self.up
    create_table :clusters do |t|
      t.primary_key :id
      t.string :product_type
      t.integer :version
      t.integer :layer
      t.integer :parent_id

      #t.timestamps
    end
  end

  def self.down
    drop_table :clusters
  end
end
