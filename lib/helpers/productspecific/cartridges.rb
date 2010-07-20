#RANDOM CARTRIDGE STUFF	
#   self.real_brands
#   init_series
#   init_brands
#   clean_color blurb
#   likely_cartridge_model_name str (deprecate & add param to likely_model_name w/default nil)
#   cartridge_cleaning_code atts, default_brand=nil, default_real=nil
#   create_uniq_compatibility acc_id, acc_type, prd_id, prd_type
#   compatibility_matches c
#   create_uniq_cartridge cart, realbrand, compatbrand
#   clean_cartridges recset, default_real=nil
#   clean_condition atts

# Cartridge-specific helper methods
module CartridgeHelper
  
  $cartridge_conditions = ['Remanufactured', 'Refurbished', 'Compatible', 'OEM', 'Genuine', 'New']
  $cartridge_colors = ['Yellow', 'Cyan', 'Magenta', 'Black']
  $fake_brands = ["123inkjets", "4inkjets", "Best Deal Toner", "Digital Products", "G & G", \
      "General Ribbon Corporation", "Global Marketing Partners", "Ink It Up 4 Less", "Ink-Power",\
       "Inkers", "LD Products", "Mega Leader", "Mipo", "Pritop", "Q-Imaging", "Sophia Global", \
       "TNT Toner", "Cartridge Family" , 'Ink Grabber']  #"SIB", "SOL", "STC", ] <-- These are weird
  
  # Creates an entry in the Compatibility table
  # unless there is already one just like it.  
  # Returns the Compatibility table entry with given attributes
  def create_uniq_compatibility acc_id, acc_type, prd_id, prd_type
    atts = {'product_id' => prd_id, 'accessory_id' => acc_id, \
        'product_type' => prd_type, 'accessory_type' => acc_type}
    compat = Compatibility.find_by_accessory_id_and_accessory_type_and_product_id_and_product_type(\
      acc_id, acc_type, prd_id, prd_type)
    compat = Compatibility.new(atts) if compat.nil?
    return compat
  end
  
  # Returns all cartridges which can be considered the same 
  # for compatibility copying purposes
  def compatibility_matches c
    matching = []
    Cartridge.all.each{ |c2|
      if same_brand?(c.compatiblebrand, c2.compatiblebrand)
        models = [c.model, c.mpn].collect!{ |x| just_alphanumeric(x) }.reject{|x| x.nil? or x == ''}
        models2 = [c2.model, c2.mpn].collect!{ |x| just_alphanumeric(x) }.reject{|x| x.nil? or x == ''}
        models.each do |m|
          models2.each do |m2|
            if( m2.match(Regexp.new(m)) or m.match(Regexp.new(m2)))
              matching << c2 
              break
            end
          end
        end
      end
    }
    return matching.uniq
  end
  
  # Cleans a string which is supposed to be the cartridge model
  def clean_ctg_model str, brand
    # TODO -- make this more general and move to cleaning helper 
    return nil if str.nil?
    str_array = str.split(' ')
    clean_str = str_array.reject{|x| same_brand?(x, brand)}.join(' ')
    str_array = clean_str.split(',')
    clean_str = str_array.reject{|x| same_brand?(x, brand)}.join(",")
    clean_str.gsub!(/^\(|\)$/,'')
    clean_str.gsub!(/\(.*\)/,'')
    clean_str.gsub!(/\s?(toner|cartridge|cyan|magenta|yellow|black|drum|compatible)/i,'')
    return clean_str.strip if clean_str
    return nil
  end
  
  # Returns a score which tells you if the 
  # string looks like a model name for a cartridge.
  # I find that >= 2 means it's probably a model name
  # that you want in your database.
  def likely_cartridge_model_name str
    return -10 if str.nil? or str.strip.length==0
    
    init_series 
    init_brands
    score = likely_model_name str
  
    score += 1 if !str.include?('/')
  
    ja = just_alphanumeric(str)
    score += 1 if !$series.inject(false){|r,x| r or ja.include?(x)}
    score -= 5 if $real_brands.inject(false){|r,x| r or ja == x}
    score -= 2 if $printer_models.inject(false){|r,x| r or ja.include?(x)}
  
    return score
  end

  # Gets a better value for brand for the given record 
  # based on the model and title attributes
  def clean_brand_rec(rec, field='brand')
    brand = clean_brand(rec.model, rec.title)
    parse_and_set_attribute(field, brand, rec) if brand
    rec
  end
  
  # Tries to find the Cartridge db record
  # with the given real & compatible brands and if it
  # can't then it makes a new one and copies the attributes
  def create_uniq_cartridge cart, realbrand, compatbrand
    
    return nil if compatbrand.nil? or cart.model.nil? #VALIDATION
    
    brand_str = "#{compatbrand}"
    if cart.real == false
      return nil if realbrand.nil? # VALIDATION
      brand_str = "#{realbrand} #{cart.condition} #{brand_str}" 
    end
    matches = find_matching_product [brand_str], [cart.model], Cartridge
    matching_c = nil
    
    if matches.length == 0
      atts = {'brand' => brand_str, 'model' => cart.model}
      matching_c = Cartridge.new(atts) 
    elsif matches.length == 1
      matching_c = matches[0]
    else
      debugger
      puts "Duplicate found"
    end
  
  end
  
  # Cleans the title; gets condition(refurbished, OEM, etc)
  # and figures out if it's toner or ink
  def clean_cartridges recset, default_real=nil
  
    # New must be last as the default
    activerecords_to_save = []
    # fill in Ink and Real
    recset.each do |x| 
      init
      # TODO Do I really want to modify the brand like that?
      clean_brand_rec(x)
      
      parse_and_set_attribute('toner', false, x) if (x.title || '').match(/ink/i)
      parse_and_set_attribute('toner', true, x) if (x.title || '').match(/toner/i) 
 
      if (x.title || '').match(/(alternative|compatible|remanufactured|refurbished)/i)
        parse_and_set_attribute('real', false, x) 
      elsif (x.title || '').match(/genuine|oem/i)
        parse_and_set_attribute('real', true, x)
      elsif !default_real.nil? and x.real.nil? and !x.title.nil?
        parse_and_set_attribute('real', default_real, x)
      end
      
      $cartridge_conditions.each do |c| 
        parse_and_set_attribute('condition', c, x) and break if (x.title || '').match(/#{c}/i)
      end
      activerecords_to_save.push(x)
    end
    if recset.first
      recset.first.class.transaction do
        activerecords_to_save.each(&:save)
      end
    end
  end
  
  # Generic cleaning code for cartridges.
  def cartridge_cleaning_code atts, default_brand=nil, default_real=nil
    atts = product_cleaner
    
    atts.each{|x,y| atts[x]= atts[y].strip if atts[y] and atts[y].class.name == 'String'}
    atts['model'].gsub!(/compatible/i,'') if atts['model']
    atts['mpn'].gsub!(/compatible/i,'') if atts['mpn']
    
    atts['toner'] = false if (atts['title'] || '').match(/ink/i)
    atts['toner'] = true if (atts['title'] || '').match(/toner/i)
    
    unless atts['title'].nil?
      atts.merge!( clean_condition atts['title'], default_real )
      atts['compatiblebrand'] = clean_brand atts['title']
      
      if atts['real'] == true
          atts['brand'] = atts['realbrand'] = atts['compatiblebrand']
      elsif atts['real'] == false and !atts['condition'].nil?
          atts['realbrand'] = clean_brand atts['title'], $fake_brands
          atts['realbrand'] = default_brand if atts['brand'].nil? and !default_brand.nil?
          atts['brand'] = "#{atts['condition']} #{atts['compatiblebrand']}"
          atts['brand'] = "#{atts['realbrand']} #{atts['brand']}" if atts['realbrand']
      end 
      
      if likely_cartridge_model_name(atts['model']) < 3
        atts['model'] = best_cartridge_model [atts['title']], atts['compatiblebrand']
      end
      
    end
    
    atts['color'] = clean_color atts['title']
    return atts
  end
  
  # Returns the string in the array that is most 
  # likely to be a cartridge model?
  def best_cartridge_model arr, brand=''    
    # Includes stuff between brackets too:
    arr_more = arr.collect{|x| [x, (x || '').match(/\(.*?\)/).to_s]}.flatten.reject{|x| x.nil? or x == ''}
    temp = arr_more.collect{|x| clean_model(x, brand)}
    arr_more += temp
    return arr_more.sort{|a,b| likely_cartridge_model_name(a) <=> likely_cartridge_model_name(b)}.last
  end
  
  def clean_condition str, default_real=nil
    retme = {}
    
    if (str || '').match(/(alternative|compatible|remanufactured|refurbished)/i)
      retme['real'] = false
    elsif (str || '').match(/genuine|oem/i)
      retme['real'] = true
    elsif !default_real.nil? and retme['real'].nil?
      retme['real'] = default_real
    end
    
    $cartridge_conditions.each{|c| retme['condition'] = c and break if str.match(/#{c}/i)}
    
    return retme
  end
  
  def clean_color blurb
    color = nil
    $cartridge_colors.each{|c|
      if blurb.match(/#{c}/i)
         color = 'All' if !color.nil?
         color = c if color.nil?
      end
    }
    return color
  end
  
  def self.real_brands
    init_brands
    return $real_brands
  end
  
  # Initializes the list of printer
  def init_series
  # TODO Just make this a global var w/o init
    return if !$series.nil?
    $series = ['laserjet', 'laserwriter', 'oki', 'phaser',  'imagerunner', 'printer', 'printers', 'qms', \
      'estudio', 'optra', 'pro', 'officejet', 'workcentre', 'other', 'okifax', 'lanierfax', 'okipage',\
      'pixma', 'deskjet', 'stylus', 'docuprint', 'series','color', 'laser', 'printer']
  end
  
  # Initializes the list of printer brands($real_brands) and cartridge refill brands($fake_brands)
  def init_brands
    return unless ($real_brands.nil? or $fake_brands.nil? or $printer_models.nil?)
    $real_brands = Printer.all.collect{|x| x.brand}.uniq.reject{|x| x.nil?}
    $real_brands += ["Apple", "Brother", "Canon", "Copystar", "DEC", "Dell", "Epson", "IBM", \
      'Kodak', "Kyocera Mita", "Lexmark", 'Lanier', "Oki Data", "Panasonic", "Pitney Bowes",\
      "Promedia", "Ricoh","Samsung", "Sharp", "Toshiba", "Xerox"]
    $real_brands.uniq!
   
    $printer_models = Printer.all.collect{|x| just_alphanumeric(x.model) }.reject{|x| x.nil? or x==''}
  end

  def parse_yield str
    return nil if str.nil?
    yld = get_f_with_units( str,  /\s?(sheet|page)(s)?/i )
    yld = get_f_with_units(str,  /\s?y(ie)?ld/i) if yld.nil?
    yld = get_f_with_units_in_front(str,  /y(ie)?ld\s*-*/i) if yld.nil?
    return yld
  end

end