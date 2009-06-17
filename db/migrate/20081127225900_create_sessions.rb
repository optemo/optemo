class CreateSessions < ActiveRecord::Migration
  def self.up
    #system "/usr/local/bin/rake db:properties"
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.string :ip
      t.integer :parent_id
      t.string :product_type
      t.boolean :filter
      t.string :searchterm
      t.string :searchpids
      (Camera::ContinuousFeatures | Printer::ContinuousFeatures).each do |f|
        min = f+'_min'
        max = f+'_max'
        pref = f + '_pref'
        t.float min.intern #, :default => f.min.to_i
        t.float max.intern #, :default => f.max.ceil
        t.float pref.intern, :default => 0
      end
      (Camera::CategoricalFeatures | Printer::CategoricalFeatures).each do |f|
        t.string f.intern, :default => "All Brands"
      end
      (Camera::BinaryFeatures | Printer::BinaryFeatures).each do |f|
        t.boolean f.intern
      end
    end
  end

  def self.down
    drop_table :sessions
  end
end
