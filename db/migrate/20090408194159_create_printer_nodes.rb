class CreatePrinterNodes < ActiveRecord::Migration
  def self.up
    create_table :printer_nodes do |t|
      t.integer :cluster_id
      t.integer :product_id
      Printer::ContiuousFeaturesF.each do |name|
        t.float f.name.intern
      end
      Printer::CategoricalFeaturesF.each do |name|
        t.string name.intern
      end
      Printer::BinaryFeaturesF.each do |name|
        t.boolean name.intern
      end
      t.float :utility
      t.string :region
      t.integer :version
    end
    add_index :printer_nodes, :product_id
    add_index :printer_nodes, :cluster_id
  end

  def self.down
    drop_table :printer_nodes
  end
end
