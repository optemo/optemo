class CreateDbProperties < ActiveRecord::Migration
  def self.up
    create_table :db_properties do |t|
      t.text  :brands
      t.float :maximumresolution_min
      t.float :maximumresolution_max
      t.float :maximumresolution_high
      t.float :maximumresolution_low
      t.float :displaysize_min
      t.float :displaysize_max
      t.float :displaysize_high
      t.float :displaysize_low
      t.float :opticalzoom_min
      t.float :opticalzoom_max
      t.float :opticalzoom_high
      t.float :opticalzoom_low
      t.float :price_min
      t.float :price_max
      t.float :price_high
      t.float :price_low

      t.timestamps
    end
  end

  def self.down
    drop_table :db_properties
  end
end
