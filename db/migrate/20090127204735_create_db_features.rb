class CreateDbFeatures < ActiveRecord::Migration
  def self.up
    create_table :db_features do |t|
      t.integer :db_property_id
      t.string :name
      t.float :min
      t.float :max
      t.float :high
      t.float :low

      t.timestamps
    end
  end

  def self.down
    drop_table :db_features
  end
end
