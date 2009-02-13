class CreateSearches < ActiveRecord::Migration
  def self.up
    @props = DbProperty.first
    create_table :searches do |t|
      t.primary_key :id
      t.integer :i0, :i1, :i2, :i3, :i4, :i5, :i6, :i7, :i8
      t.integer :c0, :c1, :c2, :c3, :c4, :c5, :c6, :c7, :c8
      t.integer :session_id
      t.integer :parent_id
      t.integer :cluster_id
      t.integer :result_count
      t.string :brand, :default => "All Brands"
      @props.db_features.each do |f|
        min = f.name+'_min'
        max = f.name+'_max'
        t.float min.intern, :default => f.min
        t.float max.intern, :default => f.max
      end
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
