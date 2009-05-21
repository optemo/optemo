class CreatePrinterNodes < ActiveRecord::Migration
  def self.up
    create_table :printer_nodes do |t|
      t.integer :cluster_id
      t.integer :product_id
      DbProperty.find_by_name('Printer').db_features.each do |f|
        t.float f.name.intern
      end
      Printer::BinaryFeatures.each do |name|
        t.boolean name.intern
      end
      t.float :price
      t.string :brand
    end
  end

  def self.down
    drop_table :printer_nodes
  end
end
