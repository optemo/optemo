module CartridgeHelper
    
  def create_uniq_compatibility acc_id, acc_type, prd_id, prd_type
    atts = {'product_id' => prd_id, 'accessory_id' => acc_id, \
        'product_type' => prd_type, 'accessory_type' => acc_type}
    compat = Compatibility.find_by_accessory_id_and_accessory_type_and_product_id_and_product_type(\
      acc_id, acc_type, prd_id, prd_type)
    compat = create_product_from_atts atts, Compatibility if compat.nil?
    return compat
  end
  
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
  
  def get_most_likely_model arr, brand=''
    # Include stuff in brackets
    arr_more = arr.collect{|x| [x, (x || '').match(/\(.*?\)/).to_s]}.flatten.reject{|x| x.nil? or x == ''}
    temp = arr_more.collect{|x| clean_model(x, brand)}
    arr_more += temp
    return arr_more.sort{|a,b| likely_to_be_cartridge_model_name(a) <=> likely_to_be_cartridge_model_name(b)}.last
  end
  
  def clean_model str, brand
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
  
  def likely_model_name str
    score = 0
    return -10 if str.nil? or str.strip.length==0
  
    ja = just_alphanumeric(str)
    score += 1 if (ja.length < 17 and ja.length > 3)
    score += 1 if (ja.length < 11 and ja.length > 4)
    score += 1 if (ja.length < 9 and ja.length > 5)
    
    score -= 2 if str.match(/[0-9]/).nil?
    str.split(/\s/).each{|x| score -= 1 if(x.match(/[0-9]/).nil?)}
    score -= 2 if str.match(/,|\./)
    score -= 1 if str.match(/for/)
    score -= 3 if str.match(/\(|\)/)
    score -= 5 if str.match(/(series|and|&)\s/i)
  
    return score
  end
  
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

  def clean_brand_rec rec, field='brand'
    brand = clean_brand(rec.model, rec.title)
    fill_in field, brand, rec if brand
  end
  
  def make_offering cart, url 
    atts = cart.attributes
    if cart.offering_id.nil?
      offer = create_product_from_atts atts, RetailerOffering
    else
      offer = RetailerOffering.find(cart.offering_id)
    end
    fill_in_all atts, offer
    fill_in 'product_type', 'Cartridge', offer
    fill_in 'toolow', false, offer
    fill_in 'priceUpdate', Time.now, offer
    fill_in 'availabilityUpdate', Time.now, offer
    fill_in 'retailer_id', 16, offer
    fill_in 'offering_id', offer.id, cart
    fill_in 'url', url, offer
    return offer
  end
  
  def create_uniq_cartridge cart, realbrand, compatbrand
    
    require 'database_helper'
    include DatabaseHelper
    
    return nil if compatbrand.nil? or cart.model.nil? #VALIDATION
    
    brand_str = "#{compatbrand}"
    if cart.real == false
      return nil if realbrand.nil? # VALIDATION
      brand_str = "#{realbrand} #{cart.condition} #{brand_str}" 
    end
    matches = match_rec_to_printer [brand_str], [cart.model], Cartridge
    matching_c = nil
    
    if matches.length == 0
      atts = {'brand' => brand_str, 'model' => cart.model}
      matching_c = create_product_from_atts atts, Cartridge
    elsif matches.length == 1
      matching_c = matches[0]
    else
      debugger
      puts "Duplicate found"
    end
  
  end
  
  def brand_from_title title, brandlist=[]
    
    init_brands if $real_brands.nil?
    brandlist = $real_brands if brandlist.length ==0
    
    if title
      brandlist.each do |b|
        return b unless just_alphanumeric(title).match(/#{just_alphanumeric(b)}/i).nil?
      end
    end
    return nil
  end
  
  def same_brand? one, two
    brands = [just_alphanumeric(one),just_alphanumeric(two)].uniq
    return false if brands.include?('') or brands.include?(nil)
    brands.sort!
    return true if brands.length == 1
    equivalent_list = [['hewlettpackard','hp'],['oki','okidata']]
    return true if equivalent_list.include?(brands)
    return false
  end
  
  def clean_cartridges recset, default_real=nil
  
    # New must be last as the default
    conditions = ['Remanufactured', 'Refurbished', 'Compatible', 'OEM', 'New']
    
    # fill in Ink and Real
    recset.each{|x| 
      init
      # TODO Do I really want to modify the brand like that?
      clean_brand_rec(x)
      
      fill_in 'toner', false, x if (x.title || '').match(/ink/i)
      fill_in 'toner', true, x if (x.title || '').match(/toner/i) 
 
      if (x.title || '').match(/(alternative|compatible|remanufactured|refurbished)/i)
        fill_in 'real', false, x 
      elsif (x.title || '').match(/genuine|oem/i)
        fill_in 'real', true, x
      elsif !default_real.nil? and x.real.nil? and !x.title.nil?
        fill_in 'real', default_real, x
      end
      
      conditions.each{|c| 
        fill_in('condition', c, x) and break if (x.title || '').match(/#{c}/i)
      }
    }
    
   
  end
  
  def init_series
    return if !$series.nil?
    $series = ['laserjet', 'laserwriter', 'oki', 'phaser',  'imagerunner', 'printer', 'printers', 'qms', \
      'estudio', 'optra', 'pro', 'officejet', 'workcentre', 'other', 'okifax', 'lanierfax', 'okipage',\
      'pixma', 'deskjet', 'stylus', 'docuprint', 'series','color', 'laser', 'printer']
  end
  
  def init_brands
    return unless ($real_brands.nil? or $fake_brands.nil? or $printer_models.nil?)
    $real_brands = Printer.all.collect{|x| x.brand}.uniq.reject{|x| x.nil?}
    $real_brands += ["Apple", "Brother", "Canon", "Copystar", "DEC", "Dell", "Epson", "IBM", \
      'Kodak', "Kyocera Mita", "Lexmark", 'Lanier', "Oki Data", "Panasonic", "Pitney Bowes",\
      "Promedia", "Ricoh","Samsung", "Sharp", "Toshiba", "Xerox"]
    $real_brands.uniq!
    $fake_brands = ["123inkjets", "4inkjets", "Best Deal Toner", "Digital Products", "G & G", \
      "General Ribbon Corporation", "Global Marketing Partners", "Ink It Up 4 Less", "Ink-Power",\
       "Inkers", "LD Products", "Mega Leader", "Mipo", "Pritop", "Q-Imaging", "Sophia Global", \
       "TNT Toner", "Cartridge Family" ]  #"SIB", "SOL", "STC", ]
    $printer_models = Printer.all.collect{|x| just_alphanumeric(x.model) }.reject{|x| x.nil? or x==''}
  end

end