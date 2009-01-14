class CreateSearches < ActiveRecord::Migration
  def self.up
    @props = DbProperty.find(:first)
    create_table :searches do |t|
      t.primary_key :id
      t.integer :i0, :i1, :i2, :i3, :i4, :i5, :i6, :i7, :i8
      t.integer :c0, :c1, :c2, :c3, :c4, :c5, :c6, :c7, :c8
      t.integer :session_id
      t.integer :parent_id
      t.integer :camera_id
      t.string :brand, :default => "All Brands"
      t.float :maximumresolution_min, :default => @props.maximumresolution_min
      t.float :maximumresolution_max, :default => @props.maximumresolution_max
      t.float :opticalzoom_min, :default => @props.opticalzoom_min
      t.float :opticalzoom_max, :default => @props.opticalzoom_max
      t.float :displaysize_min, :default => @props.displaysize_min
      t.float :displaysize_max, :default => @props.displaysize_max
      t.float :price_min, :default => @props.price_min/100
      t.float :price_max, :default => @props.price_max/100
      t.text :chosen
      t.string :msg
      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
