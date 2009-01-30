namespace :db do
  desc "Calculate properties of the camera database"
  task :properties => :environment do
    #Delete old db properties
    DbProperty.find(:all).each do |prop|
      prop.destroy
    end
    DbFeature.find(:all).each do |f|
      f.destroy
    end
    create_product_properties(Camera)
    
    
    #output results
    for column in DbProperty.content_columns
      tmp = @prop.send(column.name)
      tmp = tmp.to_s if tmp.class == Float || tmp.class == ActiveSupport::TimeWithZone
      puts column.human_name+": "+ tmp
    end
  end
end

#Support methods

def create_product_properties(model)
  #Collect new properties
  @prop = DbProperty.new
  @prop.product = model.name
  @prop.brands = model.find(:all).map{|u| u.brand}.compact.uniq.join('*')
  @prop.save
  model.MainFeatures.each {|name|
    f = DbFeature.new
    f.db_property = @prop
    f.name = name
    f.min = Camera.find(:first, :order => "#{name} ASC", :conditions => "#{name} IS NOT NULL").send(name.intern)
    f.max = Camera.find(:first, :order => "#{name} DESC").send(name.intern)
    f.high = Camera.find(:all).map{|c|c.send(name.intern)}.sort[Camera.count*0.75]
    f.low = Camera.find(:all).map{|c|c.send(name.intern)}.sort[Camera.count*0.25]
    f.save!
  }
end