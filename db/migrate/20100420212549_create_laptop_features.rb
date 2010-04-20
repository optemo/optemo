class CreateLaptopFeatures < ActiveRecord::Migration
  def self.up
    create_table :laptop_features do |t|
      t.timestamps
      t.primary_key :id
      t.integer :session_id
      t.integer :search_id
      (Laptop::ContinuousFeaturesF).each do |f|
        min = f+'_min'
        max = f+'_max'
        pref = f + '_pref'
        t.float min.intern
        t.float max.intern
        t.float pref.intern, :default => 1/Laptop::ContinuousFeaturesF.count.to_f
      end      
      (Laptop::CategoricalFeaturesF).each do |f|
        t.string f.intern
      end
      (Laptop::BinaryFeaturesF).each do |f|
        t.boolean f.intern
      end
    end
    add_index :laptop_features, :session_id
    add_index :laptop_features, :search_id
  end

  def self.down
    drop_table :laptop_features
  end
end
