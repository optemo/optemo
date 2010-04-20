class CreateCameraClusters < ActiveRecord::Migration
  def self.up
    create_table :camera_clusters do |t|
      t.primary_key :id
      t.integer :parent_id
      t.integer :layer
      t.integer :cluster_size
      t.float :cached_utility
      DbFeature.find_all_by_product_type_and_region('Camera',"us").each do |f|
         myname = f.name
        if (f.feature_type == "Continuous")
          fmin = myname+'_min'
          fmax = myname+'_max'
          t.float fmin.intern
          t.float fmax.intern
        elsif (f.feature_type == "Binary")
          t.boolean myname.intern
        else
          t.string myname.intern
        end    
      end
    end
    add_index :camera_clusters, :parent_id
    add_index :camera_clusters, :version 
    add_index :camera_clusters, :cached_utility
  end
  def self.down
    drop_table :camera_clusters
  end
end
