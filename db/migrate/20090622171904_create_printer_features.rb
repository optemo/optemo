class CreatePrinterFeatures < ActiveRecord::Migration
  def self.up
    create_table :printer_features do |t|

      t.timestamps
      t.primary_key :id
      t.integer :session_id
      (Printer::ContinuousFeatures).each do |f|
        min = f+'_min'
        max = f+'_max'
        pref = f + '_pref'
        t.float min.intern #, :default => f.min.to_i
        t.float max.intern #, :default => f.max.ceil
        t.float pref.intern, :default => 1/Printer::ContinuousFeatures.count.to_f
      end      
      (Printer::CategoricalFeatures).each do |f|
        t.string f.intern, :default => "All Brands"
      end
      (Printer::BinaryFeatures).each do |f|
        t.boolean f.intern
      end      
    end
    loadUses
  end

  def self.down
    drop_table :printer_features
  end
  
  def self.loadUses
    YAML.load(File.open("#{RAILS_ROOT}/lib/uses.yml")).each do |k,v|
        PrinterFeatures.new(v).save
    end
  end
end
