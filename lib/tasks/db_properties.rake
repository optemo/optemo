namespace :db do
  desc "Calculate properties of the camera database"
  task :properties => :environment do
    #Delete old db properties
    DbProperty.find(:all).each do |prop|
      prop.destroy
    end
    #Collect new properties
    @prop = DbProperty.new
    @prop.brands = Camera.find(:all).map{|u| u.brand}.compact.uniq.join('*')
    @prop.maximumresolution_min = Camera.find(:first, :order => "maximumresolution ASC", :conditions => 'maximumresolution IS NOT NULL').maximumresolution
    @prop.maximumresolution_max = Camera.find(:first, :order => "maximumresolution DESC").maximumresolution
    @prop.maximumresolution_high = Camera.find(:all).map{|c|c.maximumresolution}.sort[Camera.count*0.75]
    @prop.maximumresolution_low = Camera.find(:all).map{|c|c.maximumresolution}.sort[Camera.count*0.25]
    @prop.displaysize_min = Camera.find(:first, :order => "displaysize ASC", :conditions => 'displaysize IS NOT NULL').displaysize
    @prop.displaysize_max = Camera.find(:first, :order => "displaysize DESC").displaysize
    @prop.displaysize_high = Camera.find(:all).map{|c|c.displaysize}.sort[Camera.count*0.75]
    @prop.displaysize_low = Camera.find(:all).map{|c|c.displaysize}.sort[Camera.count*0.25]
    @prop.opticalzoom_min = Camera.find(:first, :order => "opticalzoom ASC", :conditions => 'opticalzoom IS NOT NULL').opticalzoom
    @prop.opticalzoom_max = Camera.find(:first, :order => "opticalzoom DESC").opticalzoom
    @prop.opticalzoom_high = Camera.find(:all).map{|c|c.opticalzoom}.sort[Camera.count*0.75]
    @prop.opticalzoom_low = Camera.find(:all).map{|c|c.opticalzoom}.sort[Camera.count*0.25]
    @prop.price_min = Camera.find(:first, :order => "listpriceint ASC", :conditions => 'listpriceint IS NOT NULL').listpriceint
    @prop.price_max = Camera.find(:first, :order => "listpriceint DESC").listpriceint
    @prop.price_high = Camera.find(:all).map{|c|c.price}.sort[Camera.count*0.75]
    @prop.price_low = Camera.find(:all).map{|c|c.price}.sort[Camera.count*0.25]
    @prop.save
    #output results
    for column in DbProperty.content_columns
      tmp = @prop.send(column.name)
      tmp = tmp.to_s if tmp.class == Float || tmp.class == ActiveSupport::TimeWithZone
      puts column.human_name+": "+ tmp
    end
  end
end