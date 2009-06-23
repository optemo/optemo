class CreateCameraFeatures < ActiveRecord::Migration
  def self.up
    create_table :camera_features do |t|

      t.timestamps
      t.primary_key :id
      t.integer :session_id
      t.string :brand, :default => "All Brands" 
      (Camera::ContinuousFeatures).each do |f|
        min = f+'_min'
        max = f+'_max'
        pref = f + '_pref'
        t.float min.intern #, :default => f.min.to_i
        t.float max.intern #, :default => f.max.ceil
        t.float pref.intern, :default => 1/Camera::ContinuousFeatures.count.to_f
      end
    end
  end

  def self.down
    drop_table :camera_features
  end
end
