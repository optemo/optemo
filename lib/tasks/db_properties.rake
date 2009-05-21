namespace :db do
  desc "Calculate properties of the product databases"
  task :properties => :environment do
    #Delete old db properties
    DbProperty.find(:all).each do |prop|
      prop.destroy
    end
    DbFeature.find(:all).each do |f|
      f.destroy
    end
    create_product_properties(Camera)
    create_product_properties(Printer)
    #output results
    @prop = DbProperty.find_by_name("Camera")
    @prop.price_low = 12000
    @prop.price_high = 59999
    @prop.save
    @prop = DbProperty.find_by_name("Printer")
    @prop.price_low = Printer.valid.instock.map{|c|c.salepriceint}.sort[Printer.valid.instock.count*0.25]
    @prop.price_high = Printer.valid.instock.map{|c|c.salepriceint}.sort[Printer.valid.instock.count*0.75]
    @prop.save
    for column in DbProperty.content_columns
      tmp = @prop.send(column.name)
      tmp = tmp.to_s if tmp.class == Float || tmp.class == ActiveSupport::TimeWithZone
      puts column.human_name+": "+tmp
    end
  end
end

#Support methods

def create_product_properties(model)
  #Collect new properties
  @prop = DbProperty.new
  @prop.name = model.name
  @prop.brands = model.instock.map{|u| u.brand}.compact.uniq.join('*')
  @prop.price_min = model.instock.map{|p| p.price}.reject{|c|c.nil?}.sort[0]
  @prop.price_max = model.instock.map{|p| p.price}.sort[-1]
  @prop.save
  model::MainFeatures.each {|name|
    f = DbFeature.new
    f.db_property = @prop
    f.name = name
    f.min = model.valid.instock.map{|c|c.send(name.intern)}.reject{|c|c.nil?}.sort[0]
    f.max = model.valid.instock.map{|c|c.send(name.intern)}.sort[-1]
    f.high = model.valid.instock.map{|c|c.send(name.intern)}.sort[model.valid.instock.count*0.75]
    f.low = model.valid.instock.map{|c|c.send(name.intern)}.sort[model.valid.instock.count*0.25]
    f.save!
  }
end