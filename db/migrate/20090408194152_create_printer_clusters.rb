class CreatePrinterClusters < ActiveRecord::Migration
  def self.up
    create_table :printer_clusters do |t|
      t.primary_key :id
      t.integer :parent_id
      t.integer :layer
      t.integer :cluster_size
      DbFeature.find_all_by_product_type('Printer').each do |f|
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
  end

  def self.down
    drop_table :printer_clusters
  end
end
