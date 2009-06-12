namespace :db do
  desc "Calculate properties of the product databases"
  task :properties => :environment do
    #Delete old db properties
    #DbProperty.find(:all).each do |prop|
    #  prop.destroy
    #end
    DbFeature.find(:all).each do |f|
      f.destroy
    end
    create_product_properties(Camera)
    create_product_properties(Printer)
    #output results
    #@prop = DbProperty.find_by_name("Camera")
    #@prop.price_low = 12000
    #@prop.price_high = 59999
    #@prop.save
    #@prop = DbProperty.find_by_name("Printer")
    #@prop.price_low = Printer.valid.instock.map{|c|c.salepriceint}.sort[Printer.valid.instock.count*0.25]
    #@prop.price_high = Printer.valid.instock.map{|c|c.salepriceint}.sort[Printer.valid.instock.count*0.75]
    #@prop.save
    #for column in DbProperty.content_columns
    #  tmp = @prop.send(column.name)
    #  tmp = tmp.to_s if tmp.class == Float || tmp.class == ActiveSupport::TimeWithZone
    #  puts column.human_name+": "+tmp
    #end
  end
end

#Support methods

def create_product_properties(model)
  #Collect new properties
  db = DbProperty.find_by_name(model.name)
  model::CategoricalFeatures.each {|name|
    f = DbFeature.new
    #f.product_type = model.name
    f.db_property_id = db.id
    f.name = name
    #f.categories = model.instock.map{|c|c.send(name.intern)}.compact.uniq.join('*')
    f.save
  }
  model::ContinuousFeatures.each {|name|
    f = DbFeature.new
    #f.product_type = model.name
    f.db_property_id = db.id
    f.name = name
    f.min = model.valid.instock.map{|c|c.send(name.intern)}.reject{|c|c.nil?}.sort[0]
    f.max = model.valid.instock.map{|c|c.send(name.intern)}.sort[-1]
    f.high = model.valid.instock.map{|c|c.send(name.intern)}.sort[model.valid.instock.count*0.75]
    f.low = model.valid.instock.map{|c|c.send(name.intern)}.sort[model.valid.instock.count*0.25]
    f.save
  }
  model::BinaryFeatures.each {|name|
    f = DbFeature.new
    #f.product_type = model.name
    f.db_property_id = db.id
    f.name = name
    f.save
  }
end