desc "Calculate Printer Resolution for an area"
task :fill_in_resolution => :environment do
  Printer.find(:all, :conditions => 'resolution is not null').each do |p|
    if !p.resolution.blank?
      p.resolutionarea = p.resolution.split(' x ').inject(1) {|a,b| a.to_i*b.to_i}
      p.save
    end
  end
end