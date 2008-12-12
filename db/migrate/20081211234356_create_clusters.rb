class CreateClusters < ActiveRecord::Migration
  def self.up
    create_table :clusters do |t|
      t.integer :session_id
      t.text :nodes
      t.timestamps
    end
  end

  def self.down
    drop_table :clusters
  end
end
