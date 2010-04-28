class CreateFlooringFeatures < ActiveRecord::Migration
  def self.up
    create_table :flooring_features do |t|
      t.timestamps
      t.primary_key :id
      t.integer :session_id
      t.integer :search_id
      (Flooring::ContinuousFeaturesF).each do |f|
        min = f+'_min'
        max = f+'_max'
        pref = f + '_pref'
        t.float min.intern
        t.float max.intern
        t.float pref.intern, :default => 1/Flooring::ContinuousFeaturesF.count.to_f
      end      
      (Flooring::CategoricalFeaturesF).each do |f|
        t.string f.intern
      end
      (Flooring::BinaryFeaturesF).each do |f|
        t.boolean f.intern
      end
    end
    add_index :flooring_features, :session_id
    add_index :flooring_features, :search_id
  end

  def self.down
    drop_table :flooring_features
  end
end
