# Rakefile and module used to scrape additional data
# such as product images and models from UPC number.

module ScrapeExtra  
  
  def do_it (p, ok_fields, interesting_fields, clean_specs)
    ok_fields.each do |field|
      parse_and_set_attribute(field, clean_specs[field], p) if p[field].blank?
    end
    interesting_fields.keys.each do |f|
      interesting_fields[f] << clean_specs[f]
    end
    p.save
    return interesting_fields
  end
  
  def get_cleaned_table dirty_table
    return {} if dirty_table.nil? or dirty_table.length == 0
    mapped_specs = {}
    dirty_table.each{|x,y| (get_property_names(x) || []).each do |prop| 
      mapped_specs[prop] = (mapped_specs[prop] || '') + "#{ScrapingHelper.sep}#{y}" unless y.nil?
      end
    }
    clean_specs = generic_printer_cleaning_code mapped_specs
    return clean_specs
  end
  
  def get_table_xerox ln
    ln_spec = ln.gsub(/\/enca.html$/, '/spec-enca.html')
    begin
      page = Nokogiri::HTML(open(ln_spec))
      table = scrape_table(page.css('table.specs tr'), 'td', 'td')
      debugger
      sleep(15)
      return table
    rescue
      return nil
    end
  end
  
  def get_table_ama asin, sesh
    
    puts 'ASIN='+asin 
    begin
      sesh.visit('http://www.amazon.com/o/asin/' + asin)
      sesh.click_link('See more technical details')
    rescue
      # NOthing 
    end
    doc = Nokogiri::HTML(sesh.response.body)
    array = doc.css('.content ul li')
    features = {}
    array.each {|i|
      t = i.content.split(': ')
      features[t[0].downcase.tr(' -\(\)_','')]=t[1] if t.length == 2
    }
    sleep(15)
    return features
    
  end
  
  def get_table_bro bp
    mdl = just_alphanumeric(bp.model || bp.mpn).downcase
    brolink = "http://www.brother-usa.com/Printer/modeldetail.aspx?PRODUCTID=#{mdl}&tab=spec"
    page = Nokogiri::HTML(open(brolink))
    table = scrape_table(page.css('table.AccSpecTable tr'), 'td.SpecTableRow span', 'td.SpecTableRow span')
    sleep(15)
    return table
  end
  
  def file_exists_for_other itemnum, sz='' # There were two functions defined with the same name. 
    begin
      image = Magick::ImageList.new(filename_from_itemnum(itemnum,sz))
      image = image.first if image.class == Magick::ImageList
      return image
    rescue
      return nil
    else
      return image
    end
    nil
  end
  
  def url_from_item_and_sz itemnum, sz
    return "/images/newegg/#{itemnum}_#{sz}.JPEG"
  end
  
  def filename_from_itemnum itemnum, sz=''
    ext = 'JPEG'
    ext = 'jpg' if sz==''
    return "#{$folder}/images/newegg/#{itemnum}#{sz}.#{ext}"
  end
  
  def resize img
  filename = img.filename.gsub(/\..+$/,'')
    scaled = []
    trimmed = img.trim
    if trimmed.rows != img.rows or trimmed.columns != img.columns
      puts "Start with #{img.rows} by #{img.columns}, end with  #{trimmed.rows} by #{trimmed.columns}" 
    end
    $sizes.each do |size|
      scaled << trimmed.resize_to_fit(size[0],size[1]) #if trimmed.columns >= size[0] or trimmed.rows >= size[1]
    end
    scaled.each_with_index do |pic, index|
      pic.write "#{filename}_#{$size_names[index]}.#{img.format}"
    end  
    return scaled.collect
  end
  
  #def precalculated_matching_sets
  #  return [[8, 4096],[10, 4146],[12, 4048],[14, 3912, 4168],[16, 3952, 4216],[18, 3974, 4044],[24, 3670, 4012],[26, 3636, 3966],[28, 3986, 4162],[30, 3714, 4164],[32, 3628, 4066],[38, 3858],[40, 4050],[44, 56],[84, 4094],[108, 3716, 3992, 3998],[110, 4274, 4284],[114, 3946],[118, 4004],[120, 4100, 4260],[122, 3724, 4298],[124, 3886],[126, 4052],[128, 3844, 3868, 4020],[130, 3718, 4210],[132, 3806, 4188, 4338],[134, 3828],[136, 3860, 4268],[138, 3910],[140, 4010],[142, 3902],[144, 4088],[146, 3696],[148, 3836, 3976, 4206],[160, 3846],[162, 3838],[164, 3866],[166, 3818, 4294],[172, 3854],[176, 3816, 4110],[178, 4174],[180, 3722],[182, 3822, 3898, 4326],[184, 3948],[188, 3668, 4190],[192, 4302],[196, 4090],[198, 3958],[200, 3702],[202, 4198, 4278],[242, 4036],[282, 4350],[284, 4242],[304, 4056],[306, 4256],[320, 4024],[322, 3826],[350, 4176],[354, 3654, 3712, 3744, 3778],[356, 4342],[366, 4382],[374, 3872, 4018],[376, 4022, 4252],[384, 3810],[468, 4364],[514, 4106],[518, 4258],[540, 3918],[542, 4226],[554, 3608, 3634, 3642, 3736, 3740, 3770, 3774, 3972, 4014, 4254],[556, 4124],[560, 3950],[562, 3840],[564, 3928, 4042, 4290],[566, 4282],[574, 3800, 4158],[576, 3624, 3638, 3730, 3764, 4016],[580, 4320, 4336],[632, 4046],[634, 4104],[636, 4104],[638, 4104],[640, 4104],[648, 4312],[652, 4232],[670, 3616, 3632, 3734, 3768, 3978, 4064, 4070, 4180],[674, 4118],[734, 4356],[756, 4112],[766, 4068],[878, 3630, 3732, 3766, 4092, 4122, 4368],[890, 3864],[892, 3882],[894, 3916],[896, 3892],[900, 4102],[902, 4214],[904, 4160],[906, 4170],[910, 4376],[928, 3980, 4222],[930, 4236],[946, 4370],[3606, 3652, 3708, 3742, 3756, 3776, 3790, 3814, 3890, 4240],[3610, 3652, 3742, 3776],[3612, 4368],[3614, 3930, 4266],[3618, 4132],[3620, 4034],[3622, 4040],[3626, 3962],[878, 3630, 3732, 3766],[670, 3616, 3632, 3734, 3768, 3978, 4070],[3640, 3700, 3738, 3752, 3772, 3786, 3842, 4344],[554, 3608, 3634, 3642, 3736, 3740, 3770, 3774, 3972],[3644, 3688, 3748, 3782, 3978],[3606, 3610, 3652, 3708, 3742, 3756, 3776, 3790],[3658, 3746, 3780],[3662, 4246, 4324],[3674, 4262, 4390],[3678, 3720, 3758, 3792, 4218],[3680, 3692],[3682, 4074],[3684, 3690, 3984],[3686, 4094],[3680, 3692, 4346],[3694, 3750, 3784],[3704, 3754, 3788],[3606, 3652, 3708, 3742, 3756, 3776, 3790],[3678, 3720, 3758, 3792, 4078],[3726, 3760, 3794, 3798],[3728, 3762, 3796],[3802, 4152],[3804, 4192],[3606, 3814],[182, 3822, 3898],[3824, 3862, 3926],[148, 3836, 3976],[3848, 3852, 4272],[128, 3844, 3868],[3606, 3890],[3904, 4234],[3914, 4310],[3964, 4280],[670, 3616, 3632, 3644, 3688, 3734, 3748, 3768, 3782, 3978, 4064, 4070, 4180],[928, 3980],[3982, 4394],[554, 3608, 3634, 3736, 3770, 3972, 4014],[128, 3844, 4020],[4028, 4318],[4032, 4078],[4038, 4374],[670, 3616, 3978, 4064, 4070],[3682, 4074, 4078],[3720, 3758, 3792, 4032, 4074, 4078, 4218, 4316],[878, 4092],[84, 3686, 4094],[900, 4102, 4160, 4170, 4214],[634, 636, 638, 640, 4104],[4116, 4334],[878, 4122],[904, 4102, 4160, 4170, 4214],[906, 4102, 4160, 4170, 4214],[670, 3616, 3978, 4070, 4180],[148, 4206],[902, 4102, 4160, 4170, 4214],[3678, 4078, 4218],[928, 4222],[3606, 4240],[3662, 4246, 4324, 4346],[554, 3608, 3634, 3736, 3770, 3972, 4254],[4078, 4316],[182, 3898, 4326],[3692, 4246, 4346],[878, 3612, 4368]]
  #end
  
end

namespace :scrape_extra do
  
  task :copy_compatibilities => :init do
  
    require 'cartridge_helper'
    include CartridgeHelper
  
    Session.current.product_type = Cartridge
    
    matching_sets = []
    Product.all.each do |rec|
      matching_ids = (compatibility_matches rec).collect{|x| x.id} 
      matching_sets << matching_ids.sort if matching_ids and matching_ids.length > 1
    end
    matching_sets.uniq!
    
    matching_sets.reject{|x| x.size < 2}.each do |set|
      addme = []
      set.each do |id|
        compats = Compatibility.valid.find_all_by_accessory_id_and_accessory_type(id, Session.current.product_type)
        addme += compats.collect{|x| [x.product_id,x.product_type]}
        addme.reject!{|x| x.nil? or x[0].nil? or x[1].nil?}
      end
      addme.each do |compat|
        set.each do |id|
          create_uniq_compatibility(id, Session.current.product_type, compat[0], compat[1])
        end
      end
    end
  end
  
  desc 'add data from xerox site'
  task :moredata_xerox => :data_init do
    Session.current.product_type = Printer
    links = []
    
    interesting_fields = ['ppm', 'paperinput', 'resolution', 'resolutionmax'].inject({}){|r, x| 
      r[x] = []
      r
    }
      
    counter = 0
    
    validids = Printer.valid.collect{|x| x.id}  
    
    # 1. Get Xerox printer links.
    2.times do |pg_index|    
      page = Nokogiri::HTML(open("scrape_me/manfpages/xerox_#{pg_index+1}.html"))
      links += page.css('form#select_form option').collect{|x| x.[]('value')}.reject{|x| x.nil? or x == ''}
    end
  
    links.uniq!
    
    links.each do |ln|
      mdl = just_alphanumeric(ln.split('/')[-2])
      if(mdl and mdl.strip != '')
        ps = find_matching_product ['xerox'], [mdl], Printer, [] # This is broken, check find_matching_product signature
        if ps.length  == 1 # and !validids.include?p.id
          p = ps.first
          #if mdl.match(/phaser/i)
           
            # THIS IS HARD because of some small variations on models being in the same table 
            
            features = get_table_xerox ln
            clean_specs = get_cleaned_table features
            counter += 1
          #end
        else
          puts " DUPLICATE " if ps.length > 1
        end
        
        
      end
    end
    
    debugger
    puts "Done!"
    
  end
  
  desc 'add data from brother'
  task :moredata_bro => :data_init do
    
    Session.current.product_type = Printer
    
    interesting_fields = ['scanner', 'printserver', 'colorprinter', 'ttp'].inject({}){|r, x| r[x]=[]
      r}
    ok_fields = ['ppm', 'resolution', 'resolutionmax', 'paperinput', 'duplex', 'colorprinter']
    # TODO re fill-in colorprinter
    validids = Printer.valid.collect{|x| x.id}  
    broprinters = Printer.find_all_by_brand('brother').reject{|w| 
      validids.include?(w.id) or (w.model || w.mpn).nil?}
      
    broprinters.each do |bp|
      
      features = get_table_bro bp
      clean_specs = get_cleaned_table features
      
      unless clean_specs['colorprinter'].nil?
        puts features['printtechnology']
        puts clean_specs['colorprinter']
        debugger 
        parse_and_set_attribute('colorprinter', clean_specs['colorprinter'], bp)
        bp.save
      end
      
      interesting_fields = do_it(bp, ok_fields, interesting_fields, clean_specs)
      
    end

      debugger
      puts " Done "
  end
  
  desc 'add data from amazon'
  task :moredata_amazon => [:data_init, :web_init] do
    
    Session.current.product_type = Printer
    
    interesting_fields = ['paperinput','scanner', 'duplex', 'printserver'].inject({}){|r, x| r[x]=[]; r}
    ok_fields = ['ppm', 'paperinput','resolution', 'resolutionmax']
    
    printerids = Printer.all.collect{|x| x.id}
    validids = (Printer.all-Printer.find_all_by_paperinput(nil)).collect{|x| x.id}
    #validids = Printer.valid.collect{|x| x.id}
    validanyway = 0
    
    seemingly_useless_flag = false# The meaning of this is not obvious.
    
    sesh = Webrat.session_class.new
    problems = 0
    
    amazonprinterids = (AmazonPrinter.all - AmazonPrinter.find_all_by_asin(nil)).reject{|x| 
      x.product_id.nil? or validids.include?(x.product_id) or !printerids.include?(x.product_id) }.collect{|x| x.id}
    
    amazonprinterids.each do |apid|
      ap = AmazonPrinter.find(apid)
      p = Printer.find(ap.product_id)
      
      features = get_table_ama(ap.asin, sesh)
      clean_specs = get_cleaned_table features
      
      
      #debugger if !p.scanner.nil? and !clean_specs['scanner'].nil? and (p.scanner xor clean_specs['scanner'])
      puts "#{p.id} rescraped"
      
      puts "No data" if clean_specs['paperinput'].nil?
      debugger unless seemingly_useless_flag
      
      ok_fields.each do |field|
        parse_and_set_attribute(field, clean_specs[field], p) if p[field].blank?
      end
      p.save
      interesting_fields.keys.each do |f|
        interesting_fields[f] << clean_specs[f]
      end
      
      sleep(15) if seemingly_useless_flag
    end
      puts "Done with #{problems} problems"
      debugger
      puts " --- "
    
  end
  
  desc 'Add data from elsewhere'
  task :moredata_lex  => :data_init do
    
    Session.current.product_type = Printer
    
    ok_fields = ['ppm', 'resolution', 'resolutionmax', 'paperinput','scanner', 'printserver']
    
    # Lexmark:
    links = []
    3.times do |pg_index|    
      page = Nokogiri::HTML(open("scrape_me/manfpages/lexmark_#{pg_index+1}.html"))
      links += page.css('div#content a').collect{|x| x.[]('href')}.uniq
    end
    puts "#{links.count} printers found in Lexmark"
    
    just_continue = false
    validids = Printer.valid.collect{|x| x.id}
    validanyway = 0
    fieldname = 'dimensions'
    debugme = []
    repeats = []
    nomatch = 0
    links.each_with_index do |link, index|
      page = Nokogiri::HTML(open(link))
      specs = scrape_table(page.css('div.specs tr'), 'td.spectitle', 'td.specinfo')
      
      mapped_specs = {}
      specs.each{|x,y| get_property_names(x).each do |prop| 
        mapped_specs_readable[prop] = (mapped_specs_readable[prop] || '') + " #{x}:#{y}" unless y.nil?
        mapped_specs[prop] = (mapped_specs[prop] || '') + "#{ScrapingHelper.sep}#{y}" unless y.nil?
        end
      }
      mapped_specs['brand'] = 'Lexmark'
      mapped_specs['model'] = get_el(page.css('div#prodInfo h1')).content if get_el(page.css('div#prodInfo h1'))
      clean_specs = generic_printer_cleaning_code mapped_specs
            
      # TODO more effective find?
      ps = find_matching_product [clean_specs['mpn']], [clean_specs['model']], Session.current.product_type,[] # This is broken, check find_matching_product signature
      if ps.length == 1
        validanyway += 1 if (validids.include?ps.first.id)
        ok_fields.each do |field|
          parse_and_set_attribute(field, clean_specs[field], ps.first) if ps.first[field].blank?
          ps.first.save
        end
      elsif ps.length == 0
        nomatch += 1 
      else
        repeats << ps.collect{|x| x.id}
      end
      debugme << clean_specs[fieldname]
      
      puts " Done #{index+1}th printer and waiting. "
      sleep(15)
      
    end
    
    puts "#{debugme.uniq.count} unique values in #{fieldname}"
    puts "#{debugme.reject{|x| !x.nil?}.count} nils in #{fieldname}"
    puts "Values in #{fieldname}:"
    puts debugme.uniq.reject{|x| x.nil?}.sort * ', '
    puts "#{nomatch} not matched "
    puts "#{validanyway} valid anyway "
    puts " Repeats listed below: "
    repeats.each{|x| 
      puts x * ','
    }
    puts " --- "
    
  end
  
  desc 'yoopsie UPC lookup'
  task :yoopsie => :init do 
    require 'webrat'
    require 'nokogiri'
    
    Webrat.configure do |conf| 
     conf.mode = :mechanize  # Can't be rails or Webrat won't work 
    end

    WWW::Mechanize.html_parser = Nokogiri::HTML
    
    @sesh = Webrat.session_class.new
    countrycode = 'US'
    
    AmazonPrinter.all.each do |ap|
      asin = ap.asin
      @sesh.visit "http://yoopsie.com/query.php?query=#{asin}&locale=#{countrycode}&index=All"
      doc = @sesh.response.parser
      equiv_id_list = doc.css('span.upc')
      upc = nil
      equiv_id_list.each do |eid|
        removeme = /upc\s?:/i
        upc_hdr = eid.text.match(removeme )
        if upc_hdr
          upc = eid.text.gsub(removeme , '')
        end
      end
      #title = doc.css('h3 a')
      
      puts "#{ap.id} | #{ap.asin} | #{upc}" if upc
      puts "No matching upc" if upc.nil?
      
      sleep(20)
    end
  end
  
  desc 'resize it'
  task :resize_all => :pic_init do

    failed = []
    NeweggPrinter.all.collect{|x| x.item_number}.each do |itemnum|
      begin
        image = Magick::ImageList.new(filename_from_itemnum itemnum)
        image = image.first if image.class == Magick::ImageList
        #unless file_exists_for( itemnum,'s')
          filenames = resize image
          failed << itemnum if filenames.length == 0
        #end
      rescue
        image = nil
        failed << itemnum
      end
    end
    
    puts " The following images weren't resized: "
    puts failed * "\n"
  end
  
  desc 'sandbox'
  task :reduced_pic_stats => :pic_init do
    
   NeweggPrinter.all.collect{|x| x.item_number}.each do |itemnum|
    #['N82E16828112055'].each do |itemnum|
      $size_names.each do |sz|
        curr_filename = filename_from_itemnum(itemnum, "_#{sz}")
        begin
          image = Magick::ImageList.new(curr_filename)
          image = image.first if image.class == Magick::ImageList
        rescue
          image = nil
        end
      
        if image
          dim = "#{sz}: #{image.rows} by #{image.columns}"
          printer = Printer.find(NeweggPrinter.find_by_item_number(itemnum).product_id)
         # if(printer.[]("image#{sz}url").nil?)
            url = url_from_item_and_sz(itemnum, sz)  
            parse_and_set_attribute("image#{sz}url", url, printer)
            parse_and_set_attribute("image#{sz}height", image.rows, printer)
            parse_and_set_attribute("image#{sz}width", image.columns, printer)
            printer.save
          #end
        end
      end
    end
  end
  
  desc 'Fills in '
  task :parse_and_set_attribute_pic_stats => :pic_init do
    no_img_sizes = []
    $size_names.each do |sz|
      no_img_sizes = no_img_sizes | Product.find( :all, :conditions => ["(img#{sz}h IS NULL OR img#{sz}w IS NULL) AND img#{sz}url IS NOT NULL"])
    end  
    
    no_img_sizes.each do |printer|
      image = nil
      $size_names.each do |sz|        
        begin
          unless printer.[]( "image#{sz}url" ).nil?
            image = Magick::ImageList.new(printer.[]( "image#{sz}url" ))
            image = image.first if image.class == Magick::ImageList
          end
        rescue
          image = nil
        end
        if image
          parse_and_set_attribute("image#{sz}height", image.rows, printer) if image.rows
          parse_and_set_attribute("image#{sz}width", image.columns, printer) if image.columns
          activerecords_to_save.push(printer)
        end
      end
    end
    Product.transaction do
      activerecords_to_save.each(&:save)
    end
  end
  
  desc 'sandbox'
  task :pic_stats => :pic_init do
    
    resolutions = {}
    dimensions = {}
    NeweggPrinter.all.collect{|x| x.imageurl}.each do |filename|
      begin
        image = Magick::ImageList.new(@folder+filename)
        image = image.first if image.class == Magick::ImageList
      rescue
        image = nil
      end
      if image
        res = "#{image.x_resolution} by #{image.y_resolution} "
        dim = "#{image.rows} by #{image.columns}"
        
        if resolutions[res].nil?
          resolutions[res] = 1
        else 
          resolutions[res] += 1
        end
        if dimensions[dim].nil?
          dimensions[dim] = 1
        else 
          dimensions[dim] += 1
        end
        
      end
    end
    
    resolutions.each do |r,n|
      puts "#{r} : #{n} times"
    end
    puts "Dimensions"
    
    dimensions.each do |x,n|
      puts "#{x} : #{n} times"
    end
  end
  
  desc 'Get a pic for every printer'
  task :download_newegg_pix => :pic_init do
    
    failed = []
    
    NeweggPrinter.all.each do |x|
      unless x.imageurl.nil? or x.imageurl.empty? or file_exists_for(x.item_number)
        
        oldurl = "http://c1.neweggimages.com/NeweggImage/productimage/" + x.imageurl.split('/').pop
        newurl = download_image oldurl, 'images/newegg', "#{x.item_number}.jpg"
        if(newurl.nil?) # TODO hacky
          oldurl = "http://images17.newegg.com/is/image/newegg/" + x.imageurl.split('/').pop
          newurl = download_image oldurl, 'images/newegg', "#{x.item_number}.jpg"
        end
        
        if(newurl.nil?)
          failed << x.item_number 
        end
        
        puts " Waiting waiting. Downloaded #{oldurl} into #{newurl}."
        sleep(30)
      end
    end
    puts " FAILED DOWNLOADS" if failed.length > 0
    puts failed * "\n"
  end
  
  desc 'Get a pic for every printer'
  task :download_pix => :pic_init do
    
    failed = []
    todo = Session.current.product_type.find_all_by_imagesurl(nil)
    
    todo.each do |product|
      pic_urls = $scraped_model.find_all_by_product_id(product.id).collect{|x| x.imageurl}.reject{|x| x.nil?}
      if pic_urls.length == 0
        # TODO log it
        failed << product.id
      else
        # download it
        download_image pic_urls.first, 'images/printers', "#{product.id}.jpg"
        # resize it
        
      end
      
      
    end
    
    puts " FAILED DOWNLOADS" if failed.length > 0
    puts failed * "\n"
  end
  
  
  task :printer_init do
      Session.current.product_type = Printer
      $scraped_model = ScrapedPrinter
  end
  
  task :pic_init => :init do
  
    require 'RMagick'
    include ScrapeExtra
  
  end
  
  task :data_init => :init do
    
    require 'rubygems'
    require 'nokogiri'

    require 'conversion_helper'
    include ConversionHelper

    require 'database_helper'
    include DatabaseHelper
    
    require 'validation_helper'
    include ValidationHelper
    
    
  end
  
  task :web_init do
    
    require 'webrat'
    require 'mechanize' # Needed to make Webrat work
    
    Webrat.configure do |conf| 
     conf.mode = :mechanize  # Can't be rails or Webrat won't work 
    end

    WWW::Mechanize.html_parser = Nokogiri::HTML
  end
  
  desc 'init'
  task :init => :environment do
    include ScrapeExtra
    
    $folder= 'public'
    $size_names = ['s','ms','m','l']
    $sizes = [[70,50],[64,64],[140,100],[400,300]]
  end
  
end 