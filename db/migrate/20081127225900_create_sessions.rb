class CreateSessions < ActiveRecord::Migration
  def self.up
    #system "/usr/local/bin/rake db:properties"
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.string :ip
      t.integer :parent_id
      t.string :brand, :default => "All Brands"
      DbFeature.find(:all).each do |f|
        min = f.name+'_min'
        max = f.name+'_max'
        t.float min.intern, :default => f.min.to_i
        t.float max.intern, :default => f.max.ceil
      end
      t.float :price_min, :default => 0
      t.float :price_max, :default => 10000000
    end
  end

  def self.down
    drop_table :sessions
  end
end
