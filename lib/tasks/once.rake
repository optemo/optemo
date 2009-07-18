desc "Calculate Printer Resolution for an area"
task :fill_in_resolution => :environment do
  AmazonPrinter.find(:all, :conditions => 'resolution is not null').each do |p|
    if !p.resolution.blank?
      #p.resolutionarea = p.resolution.split(' x ').inject(1) {|a,b| a.to_i*b.to_i}
      p.resolutionmax = p.resolution.split(' x ')[0]
      p.save
    end
  end
end

desc "Fix wrong model names MODEL=Printer|Camera"
task :fix_model_names => :environment do
  pt = ENV['MODEL']
  pt.constantize.find(:all, :conditions => 'mpn = model').each do |p|
    /(\w+ )?([\w\-\/_]*[0-9][\w\-\/_]*)/ =~ p.title
    w = Regexp.last_match(1).rstrip if Regexp.last_match(1)
    if w && (w.downcase == p.brand.downcase || 
      (pt == "Printer" && (w == "Printer" || w == 'LaserJet' || w == 'Laserjet' || w =='HP' || w == 'Okidata')))
      p.model = Regexp.last_match(2)
    else
      p.model = Regexp.last_match(0)
    end
    p.save
    print '.'
  end
end

desc "Match BB to Amazon"
task :match_printers => :environment do
  total = BestBuyPrinter.all.count
  missed = 0
  BestBuyPrinter.all.each do |p|
    if Printer.find_by_model(p.modelNumber).nil?
      match = nil
      Printer.all.each do |printer|
        if printer.model && printer.model.index(p.modelNumber)
          if match.nil?
            match = printer
          else
            raise StandardException "Double match"
          end
        end
      end
      if match.nil?
        missed+=1
      else
        p.printer_id = match
        p.save
      end
    else
      p.printer_id = Printer.find_by_model(p.modelNumber).id
      p.save
    end
  end
  puts "Matches: " + (total-missed).to_s + '/' +total.to_s
end

desc "Copy Camera info"
task :copy_camera => :environment do
  Camera.all.each do |c|
    p = Phlamera.new(c.attributes)
    p.save
  end
end

desc "Copy AmazonAll info"
task :copy_amazonall => :environment do
  AmazonAll.all.each do |c|
    p = AmazonPrinter.new(c.attributes)
    p.save
  end
end

desc "Remove duplicate asins"
task :remove_double_asins => :environment do
prev = nil
dups = []
Printer.all.map{|p|p.asin}.sort.each do |p|
  dups << p if p == prev
  prev = p
end
dups.each do |asin|
  dead = Printer.find_all_by_asin(asin)[1].id
  RetailerOffering.find_all_by_product_id_and_product_type(dead,'Printer').each {|ro|ro.destroy}
  Printer.find(dead).destroy
end
#Printer.find_all_by_brand(nil, :conditions => ["manufacturer LIKE (?)", "%LEXMARK%"]).update_attribute('brand','Lexmark')

end

desc "Copy itemwidth from AmazonPrinter to Printer"
task :fill_in_itemwidth => :environment do
  AmazonPrinter.find(:all, :conditions => ['created_at > ?', 4.days.ago]).each do |p|
    Printer.find(p.product_id).update_attribute('itemwidth', p.itemwidth)
  end
end

desc "Remove duplicate product entries"
task :remove_duplicates => :environment do
  #model = ENV['Model']
  ids = ENV['Ids'].split(',')
  return if ids.length != 2
  keep = ids[0]
  del = ids[1]
  #Check AmazonPrinter for model
  AmazonPrinter.find_all_by_product_id(del).each do |p|
    puts "Updating AmazonPrinter #{p.id}"
    p.update_attribute('product_id',keep)
  end
  #Check NeweggPrinter for model
  NeweggPrinter.find_all_by_product_id(del).each do |p|
    puts "Updating NeweggPrinter #{p.id}"
    p.update_attribute('product_id',keep)
  end
  #Reassign RetailOfferings
  RetailerOffering.find_all_by_product_id_and_product_type(del,"Printer").each do |p|
    puts "Updating RetailerOffering #{p.id}"
    p.update_attribute('product_id',keep)
  end
  
  keep_p = Printer.find(keep)
  del_p = Printer.find(del)
  #Reassign Reviews
  if !Review.find_all_by_product_id_and_product_type(del,"Printer").nil?
    #Recalculate review numbers
    del_avg = del_p.averagereviewrating.nil? ? 0 : del_p.averagereviewrating
    del_num = del_p.totalreviews.nil? ? 0 : del_p.totalreviews
    keep_avg = keep_p.averagereviewrating.nil? ? 0 : keep_p.averagereviewrating
    keep_num = keep_p.totalreviews.nil? ? 0 : keep_p.totalreviews
    keep_p.totalreviews = del_num + keep_num
    keep_p.averagereviewrating = keep_p.totalreviews == 0 ? 0 : (del_avg*del_num + keep_avg*keep_num)/keep_p.totalreviews
    keep_p.save
    Review.find_all_by_product_id_and_product_type(del,"Printer").each do |p|
      puts "Updating Review #{p.id}"
      p.update_attribute('product_id',keep)
    end
  end
  
  #Copy over useful attributes
  newatts = {}
  keep_p.attributes.delete_if{|k,v|!v.nil?}.each_pair{|k,v|newatts[k] = del_p.send(k.intern)}
  keep_p.update_attributes(newatts)
  
  #Remove model entry
  puts "Removing Printer #{del}"
  Printer.find(del).destroy
end