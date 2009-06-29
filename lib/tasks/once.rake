desc "Calculate Printer Resolution for an area"
task :fill_in_resolution => :environment do
  Printer.find(:all, :conditions => 'resolution is not null').each do |p|
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