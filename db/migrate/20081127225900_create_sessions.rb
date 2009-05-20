class CreateSessions < ActiveRecord::Migration
  def self.up
    #system "/usr/local/bin/rake db:properties"
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      DbFeature.find(:all).each do |f|
        min = f.name+'_min'
        max = f.name+'_max'
        hist = f.name+'_hist'
        t.float min.intern, :default => f.min.to_i
        t.float max.intern, :default => f.max.ceil
        t.string hist.intern
      end
      t.float :price_min, :default => 0
      t.float :price_max, :default => 10000000
      t.string :price_hist
      t.integer :result_count
      t.integer :i0, :i1, :i2, :i3, :i4, :i5, :i6, :i7, :i8
      t.integer :c0, :c1, :c2, :c3, :c4, :c5, :c6, :c7, :c8
      t.text :chosen
      t.string :msg
      t.string :ip
    end
  end

  def self.down
    drop_table :sessions
  end
end
