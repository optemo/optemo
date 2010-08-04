namespace :refills do
  
  task :test_123_local_ids => [:ctg_init, :one23_init, :test_get_localids]
  task :test_grabber_local_ids => [:ctg_init, :grab_init, :test_get_localids]
  
  task :blah => [:ctg_init, :one23_init] do
    url = 'http://www.inkgrabber.com/printers.mhtml?search_for=Brother'
    nokopage = Nokogiri::HTML(open(url))
    puts "#{nokopage.css('div').count} divs"
    debugger
    puts "Done"
  end
  
  task :test_get_localids do
    $retailers.each do |ret|
      start = Time.now
      region = ret.region
      x = scrape_all_local_ids(region)
      puts "#{x.count} local ids"
      puts "Took #{totaltime} minutes"
      debugger
      puts "Done getting local ids for #{region}"
    end
    totaltime = (Time.now - start)/60.0
  end
  
  # Scrape all data for new products only
  task :scrape_new do
    puts "Implement Me"
    #@logfile = File.open("./log/scrape/refills/#{just_alphanumeric($retailers.first.name)}_#{Session.current.product_type}.log", 'w+')
    #$retailers.each do |retailer|
    #  ids = scrape_all_local_ids retailer.region
    #  scraped_ids = ($scrapedmodel.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}.uniq
    #  ids = (ids - scraped_ids).uniq.reject{|x| x.nil?}
    #  announce "Will scrape #{ids.count} #{Session.current.product_type}s from #{retailer.name}, #{scraped_ids.count} already exist"
    #  
    #  ids.each_with_index do |local_id, i|
    #    generic_scrape(local_id, retailer)
    # TODO compatibilities  
    #    log "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{Session.current.product_type}s..."
    #  end
    #end
    #timed_announce "Done scraping"
    #@logfile.close unless @logfile.closed?
  end
  
  
  task :compatibilities do
    puts "Implement Me"
  end
  
  task :grab_init do
    $retailers = [18].collect{|x| Retailer.find(x)}
    require 'helpers/sitespecific/inkgrabber_scraper'
    include InkgrabberScraper
  end
  
  task :one23_init do
    $retailers = [16].collect{|x| Retailer.find(x)}
    require 'helpers/sitespecific/one23_scraper'
    include One23Scraper
  end

  # Cartridge init
  task :ctg_init => 'data:init' do
    #  include PrinterHelper
    #  include PrinterConstants
    #  
    #  # TODO get rid of this construct:
    #  Session.current.product_type = @@model
    #  $scrapedmodel = @@scrapedmodel
    #  $brands= @@brands
    #  $series = @@series
    #  $descriptors = @@descriptors + $conditions.collect{|cond| /(\s|^|;|,)#{cond}(\s|,|$)/i}
    #  # \
    #  #  + $units.reject{|x| x=='in'}.collect{|y| /#{Regexp.escape(y)}/i}
    #  
    #  $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
    #     'paperinput','scanner', 'printserver', 'brand', 'model']
    #  $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
    #     'local_id', "product_type", "region", "retailer_id"]
    
    Session.current.product_type = Cartridge
  end
end