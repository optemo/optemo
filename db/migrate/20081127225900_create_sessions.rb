class CreateSessions < ActiveRecord::Migration
  def self.up
    #system "/usr/local/bin/rake db:properties"
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.string :ip
      t.integer :parent_id
      t.string :product_type
      t.string :brand, :default => "All Brands"
      t.boolean :filter
      
      (Camera::MainFeatures | Printer::MainFeatures).each do |f|
        min = f + '_min'
        max = f + '_max'
        pref = f + '_pref'
        t.float min.intern #, :default => f.min.to_i
        t.float max.intern #, :default => f.max.ceil
        t.float pref.intern, :default => 0
      end      
      t.float :price_min, :default => 0
      t.float :price_max, :default => 10000000

      # Since we do not have Price in the sessions table (because it is not present in MainFeatures)
      # This will go once Camera::MainFeatures is changed to Camera::ContinuousFeatures
      t.float :price_pref, :default => 0
    end
  end

  def self.down
    drop_table :sessions
  end
end
