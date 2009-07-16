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
        #Set both min and max from the db:features field
        dbfeat = {}
        flip = {"min" => "max", "max" => "min"}
        DbFeature.find_all_by_product_type(Printer.name).each {|f| dbfeat[f.name] = f}
        v.keys.each do |key|
          if key.index(/(.+)_(min|max)/) && !v.keys.include?(Regexp.last_match[1]+flip[Regexp.last_match[2]])
            feat = Regexp.last_match[1]+"_"+flip[Regexp.last_match[2]]
            v.merge!({feat => dbfeat[Regexp.last_match[1]].send(flip[Regexp.last_match[2]].intern)})
          end
        end
        PrinterFeatures.new(v).save
    end
  end
end
