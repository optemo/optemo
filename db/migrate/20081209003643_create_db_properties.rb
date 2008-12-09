class CreateDbProperties < ActiveRecord::Migration
  def self.up
    create_table :db_properties do |t|
      t.string :brands
      t.float :maximumresolution_max
      t.float :maximumresolution_min
      t.float :displaysize_min
      t.float :displaysize_max
      t.float :opticalzoom_max
      t.float :opticalzoom_min
      t.float :price_min
      t.float :price_max

      t.timestamps
    end
  end

  def self.down
    drop_table :db_properties
  end
end
