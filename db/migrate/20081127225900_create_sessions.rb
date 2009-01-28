class CreateSessions < ActiveRecord::Migration
  def self.up
    system "/usr/local/bin/rake db:properties"
    @props = DbProperty.find(:first)
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.datetime :loaded_at
      t.string :brand, :default => "All Brands"
      t.float :f1_min, :default => @props.f1_min
      t.float :f1_max, :default => @props.f1_max
      t.float :f2_min, :default => @props.f2_min
      t.float :f2_max, :default => @props.f2_max
      t.float :f3_min, :default => @props.f3_min
      t.float :f3_max, :default => @props.f3_max
      t.float :f4_min, :default => @props.f4_min
      t.float :f4_max, :default => @props.f4_max
      t.float :price_min, :default => @props.price_min/100
      t.float :price_max, :default => @props.price_max/100
    end
  end

  def self.down
    drop_table :sessions
  end
end
