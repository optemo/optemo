class CreateCameraFeatures < ActiveRecord::Migration
  def self.up
    create_table :camera_features do |t|
      t.timestamps
      t.primary_key :id
      t.integer :session_id
      t.integer :search_id
      (Camera::ContinuousFeaturesF).each do |f|
        min = f+'_min'
        max = f+'_max'
        pref = f + '_pref'
        t.float min.intern
        t.float max.intern
        t.float pref.intern, :default => 1/Camera::ContinuousFeaturesF.count.to_f
      end      
      (Camera::CategoricalFeaturesF).each do |f|
        t.string f.intern
      end
      (Camera::BinaryFeaturesF).each do |f|
        t.boolean f.intern
      end
      add_index :session_id, :search_id
    end
  end

  def self.down
    drop_table :camera_features
  end
end
