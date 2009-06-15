class CreateDbFeatures < ActiveRecord::Migration
  def self.up
    create_table :db_features do |t|
      t.string :product_type
      t.string :name
      t.float :min
      t.float :max
      t.float :high
      t.float :low
      t.text :categories
      t.timestamps
    end
  end

  def self.down
    drop_table :db_features
  end
end
