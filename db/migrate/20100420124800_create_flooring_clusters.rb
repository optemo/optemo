class CreateFlooringClusters < ActiveRecord::Migration
  def self.up
     create_table :flooring_clusters do |t|
       t.primary_key :id
       t.integer :parent_id
       t.integer :layer
       t.integer :cluster_size
       t.float :cached_utility
       t.integer :version
       t.string :region
       DbFeature.find_all_by_product_type_and_region('Flooring',"us").each do |f|
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
     add_index :flooring_clusters, :parent_id
     add_index :flooring_clusters, :version 
     add_index :flooring_clusters, :cached_utility
  end
  def self.down
    drop_table :flooring_clusters
  end
end
