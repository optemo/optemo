class CreateSessions < ActiveRecord::Migration
  def self.up
    system "/usr/local/bin/rake db:properties"
    @props = DbProperty.find(:first)
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.datetime :loaded_at
      t.string :brand, :default => "All Brands"
      t.float :maximumresolution_min, :default => @props.maximumresolution_min
      t.float :maximumresolution_max, :default => @props.maximumresolution_max
      t.float :opticalzoom_min, :default => @props.opticalzoom_min
      t.float :opticalzoom_max, :default => @props.opticalzoom_max
      t.float :displaysize_min, :default => @props.displaysize_min
      t.float :displaysize_max, :default => @props.displaysize_max
      t.float :price_min, :default => @props.price_min/100
      t.float :price_max, :default => @props.price_max/100
    end
  end

  def self.down
    drop_table :sessions
  end
end
