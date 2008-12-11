namespace :db do
  desc "Calculate properties of the camera database"
  task :properties => :environment do
    #Delete old db properties
    DbProperty.find(:all).each do |prop|
      prop.destroy
    end
    #Collect new properties
    @prop = DbProperty.new
    @prop.brands = Camera.find(:all).map{|u| u.brand}.compact!.uniq!.join('*')
    @prop.maximumresolution_min = Camera.find(:first, :order => "maximumresolution ASC", :conditions => 'maximumresolution IS NOT NULL').maximumresolution
    @prop.maximumresolution_max = Camera.find(:first, :order => "maximumresolution DESC").maximumresolution
    @prop.displaysize_min = Camera.find(:first, :order => "displaysize ASC", :conditions => 'displaysize IS NOT NULL').displaysize
    @prop.displaysize_max = Camera.find(:first, :order => "displaysize DESC").displaysize
    @prop.opticalzoom_min = Camera.find(:first, :order => "opticalzoom ASC", :conditions => 'opticalzoom IS NOT NULL').opticalzoom
    @prop.opticalzoom_max = Camera.find(:first, :order => "opticalzoom DESC").opticalzoom
    @prop.price_min = Camera.find(:first, :order => "listpriceint ASC", :conditions => 'listpriceint IS NOT NULL').listpriceint
    @prop.price_max = Camera.find(:first, :order => "listpriceint DESC").listpriceint
    @prop.save
    #output results
    for column in DbProperty.content_columns
      tmp = @prop.send(column.name)
      tmp = tmp.to_s if tmp.class == Float || tmp.class == ActiveSupport::TimeWithZone
      puts column.human_name+": "+ tmp
    end
  end
end