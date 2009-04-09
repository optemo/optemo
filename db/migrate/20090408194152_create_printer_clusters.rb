class CreatePrinterClusters < ActiveRecord::Migration
  def self.up
    create_table :printer_clusters do |t|
      t.primary_key :id
      t.integer :parent_id
      t.integer :layer
      t.integer :cluster_size
      DbProperty.find_by_name('Printer').db_features.each do |f|
        min = f.name+'_min'
        max = f.name+'_max'
        t.float min.intern
        t.float max.intern
      end
      t.float :price_max, :price_min
    end
  end

  def self.down
    drop_table :printer_clusters
  end
end
