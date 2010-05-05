class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.primary_key :id
      t.integer :cluster_id
      t.integer :product_id
      t.string :product_type
      t.integer :version

      #t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
