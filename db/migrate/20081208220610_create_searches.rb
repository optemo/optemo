class CreateSearches < ActiveRecord::Migration
  def self.up
    @props = DbProperty.find(:first)
    create_table :searches do |t|
      t.primary_key :id
      t.integer :i0, :i1, :i2, :i3, :i4, :i5, :i6, :i7, :i8
      t.integer :c0, :c1, :c2, :c3, :c4, :c5, :c6, :c7, :c8
      t.integer :session_id
      t.integer :parent_id
      t.integer :cluster_id
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
      t.text :chosen
      t.string :msg
      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
