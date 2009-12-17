# Methods for the database.
# Note: for more update methods see fillin_helper.rb
module DatabaseHelper
  
  $ca = {'price'=>'price_ca', 'pricestr' => 'price_ca_str', 'bestoffer' => 'bestoffer_ca', 'instock'=> 'instock_ca','prefix' => 'CAD'}
  $us = {'price'=>'price', 'pricestr' => 'pricestr', 'bestoffer' => 'bestoffer', 'prefix' => '', 'instock'=> 'instock'}
  
  # The idea for ignore lists is that we don't copy over 
  # certain attributes because they're automatically generated
  # or because we don't want to. The ones which are auto-generated
  # are listed in the general ignore list:  
  $general_ignore_list = ['id','created_at','updated_at']
  
  # For internal use.
  $region_suffixes = {'CA' => '_ca', 'US' => ''}
  
  # Does record_updated_price and copies 
  # over other offering attributes as well.
  def update_offering newparams, offering
    newprice = newparams['priceint']
    record_updated_price newprice, offering if newprice
    fill_in_all newparams, offering
  end
  
  # Records a new price for the given offering
  # if the price has changed. Also puts a time
  # stamp (priceUpdate) and puts the latest thing
  # in the price history.
  def record_updated_price newprice, offering
    if offering.priceint.to_s != newprice.to_s # Save old prices only if price has changed
      
      # Write the old price down in the history
      if offering.pricehistory.nil? and offering.priceUpdate
        pricehistory = [offering.priceUpdate.to_s(:db), offering.priceint].to_yaml
      elsif offering.priceUpdate
        pricehistory = (YAML.load(offering.pricehistory) + [offering.priceUpdate.to_s(:db), \
          offering.priceint]).to_yaml
      else
        pricehistory = nil
      end
      fill_in 'pricehistory', pricehistory, offering
      
      # Update price & timestamp
      fill_in 'priceint', newprice, offering
      fill_in 'priceUpdate', Time.now, offering
    end
  
  end
  
  def timestamp_offering ro
    fill_in 'availabilityUpdate', Time.now, ro
    fill_in 'priceUpdate', Time.now, ro
    return ro
  end
  
  # TODO
  #def get_matching_sets_efficient recs=$model.all
  #   matchingsets = []
  #   recclass = recs.first.class
  #   
  #   data_i_need = recs.collect{|rec| [rec.id, rec.brand, rec.model, rec.mpn]}
  #   
  #   data_i_need.each do |row|
  #     #matchingsets << (match_printer_to_printer rec, recclass, []).collect{|x| x.id}
  #     makes = [row[1]]
  #     modelnames = [row[2], row[3]]
  #     matchingsets << match_rec_to_printer(makes, modelnames,recclass, $series)
  #   end
  #   matchingsets.collect{|x| x.sort}.uniq
  #   return matchingsets
  #end
  
  # Returns sets of IDs of records that match. eg
  # [[1,2], [3], [4,5,6]] means records with id 1 and 2
  # are the same product; 3 doesn't match any others,
  # just itself; and 4,5,and 6 are also the same product.
  # OK to used for any db model that can be compared 
  # by the brand, model, and mpn attributes.
  def get_matching_sets recs=$model.all
     matchingsets = []
     recclass = recs.first.class
     recs.each do |rec|
       matchingsets << (match_printer_to_printer rec, recclass, []).collect{|x| x.id}
     end
     matchingsets.collect{|x| x.sort}.uniq
     return matchingsets
  end
  
  # Returns itself and any other matching printers(or other specified model)
  def match_printer_to_printer ptr, recclass=$model, series=[]
    makes = [just_alphanumeric(ptr.brand)].reject{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].reject{ |x| x.nil? or x == ""}
    
    return match_rec_to_printer makes, modelnames,recclass, series
  end
  
  # Finds a record of the given db model by 
  # possible make(aka brand) and model lists. 
  # Example: match_rec_to_printer( ['HP','hewlett-packard'],  ['Q123xd',nil], Printer)
  # The series is used to clean the model name, in case you had "Phaser 100abc"
  # Then if you list "Phaser" in the series, it'll try to match "100abc" as the model name too.
  def match_rec_to_printer rec_makes, rec_modelnames, recclass=$model, series=[]
    matching = []
    makes = rec_makes.collect{ |x| just_alphanumeric(x) }.reject{|x| x.nil? or x == ''}
    return nil if makes.size == 0
    makes.each do |make|
      $brand_alternatives.each do |altmakes|
        altmakes.collect{|x| just_alphanumeric(x)}.each do |altmake|
          if make.include? altmake or altmake.include? make
            makes += altmakes and break
          end
        end
      end
    end
    makes.uniq
    modelnames = []
    rec_modelnames.collect{ |x| just_alphanumeric(x) }.uniq.each{ |mn|  
      modelnames << mn
      series.collect{|x| just_alphanumeric(x)}.each { |ser| 
        modelnames << just_alphanumeric(mn).gsub(/#{ser}/i,'')
        modelnames.uniq!
      }
    }
    modelnames.reject{|x| x.nil? or x == ''}.each{|x| makes.each{|y| x.gsub!(/#{y}/,'')}}.uniq!
    
    recclass.all.each do |ptr|
      p_makes = [just_alphanumeric(ptr.brand)].reject{ |x| x.nil? or x == ""}
      p_modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].reject{ |x| x.nil? or x == ""}

      series.each { |ser| p_modelnames.each {|pmn| pmn.gsub!(/#{ser}/,'') } }

      matching << ptr unless ( (p_makes & makes).empty? or (p_modelnames & modelnames).empty? )
    end
    return matching
  end
  
  # TODO this is now obsolete...
  def find_or_create_scraped_printer atts 
      puts "WARNING: using obsolete method, find_or_create_scraped_printer. Use find_or_create_scraped_product instead!"
      rid = atts['retailer_id']
      lid = atts['local_id']
      return nil if rid.nil? or lid.nil?
      sp = ScrapedPrinter.find_by_retailer_id_and_local_id(rid,lid)
      if sp.nil?
        sp = create_product_from_atts atts, ScrapedPrinter
      else
        fill_in_all atts, sp
      end
      return sp
  end

  def find_or_create_scraped_product atts 
      rid = atts['retailer_id']
      lid = atts['local_id']
      return nil if rid.nil? or lid.nil?
      sp = $scrapedmodel.find_by_retailer_id_and_local_id(rid,lid)
      if sp.nil?
        sp = create_product_from_atts atts, $scrapedmodel
      else
        fill_in_all(atts, sp)
      end
      return sp
  end
  
  # Creates a record and fills in any fitting attributes
  # from the given attribute hash
  def create_product_from_atts atts, recclass=$model
    atts_to_copy = only_overlapping_atts atts, recclass
    p = recclass.new(atts_to_copy)
    p.save
    return p
  end
  
  # Like creating a product from the record's attributes
  def create_product_from_rec rec, recclass=$model
    return create_product_from_atts rec.attributes, recclass
  end
  
  # Makes a retailer offering from a specific brand's offering.
  # Checks if there is already a matching retailer offering via
  # the offering_id field and if not, copies over all attributes 
  # from the specific brand's offering into a new RetailerOffering
  def create_retailer_offering specific_o, product, model=$model
    o  =  find_or_create_offering specific_o, specific_o.attributes
    
    fill_in 'product_type', model.name, o # TODO
    fill_in 'product_id', product.id, o
    
    return o
  end
  
  def find_or_create_offering rec, atts
    if rec.offering_id.nil? # If no RetailerOffering is mapped to this brand-specific offering:
      o = create_product_from_atts atts, RetailerOffering
      fill_in 'offering_id', o.id, rec
    else
      o = RetailerOffering.find(rec.offering_id)
      fill_in_all atts, o
    end
    timestamp_offering o
    return o
  end
  
  # Updates best offer for all regions
  def update_bestoffer p
    $region_suffixes.keys.each do |region|
      update_bestoffer_regional p, region
    end
    
  end
  
  # Finds the best offer by region and records the new
  # bestoffer price and product id.
  def update_bestoffer_regional p, region
    matching_ro = RetailerOffering.find(:all, :conditions => \
      "product_id LIKE #{p.id} and product_type LIKE '#{$model.name}' and region LIKE '#{region}'").\
      reject{ |x| !x.stock or x.priceint.nil? }
    if matching_ro.empty?
      fill_in "instock#{$region_suffixes[region]}", false, p
      return
    end
    
    lowest = matching_ro.sort{ |x,y|
      x.priceint <=> y.priceint
    }.first
    
    regional = case region 
      when 'CA' then $ca
      when 'US' then $us
      else []
    end
    fill_in regional['bestoffer'], lowest.id, p
    fill_in regional['price'], lowest.priceint, p
    fill_in regional['pricestr'], "#{regional['prefix']}#{lowest.pricestr}", p
    fill_in regional['instock'], true, p
  end
  
  # Returns a hash of only those attributes which :
  # 1. have non-nil values
  # 2. are 'applicable to' (exist for) the given model 
  # (eg displaysize doesn't exist for Cartridge)
  # 3. are not in the given ignore list or the usual ignore list
  def only_overlapping_atts atts, other_recs_class, ignore_list=[]
    big_ignore_list = ignore_list + $general_ignore_list
    overlapping_atts = atts.reject{ |x,y| 
      y.nil? or not other_recs_class.column_names.include? x \
      or big_ignore_list.include? x }
    return overlapping_atts
  end
  
  # Gets Scraped Printer entries by a list of 
  # matching retailer ids, where none of the SPs
  # are matched to a Printer.
  def scraped_by_retailers retailer_ids, scrapedmodel=$scrapedmodel, unmatched_only=true
     sps = []
     retailer_ids.each do |ret|
       if unmatched_only
         sps = sps | scrapedmodel.find_all_by_retailer_id_and_product_id(ret,nil)
       else
         sps = sps | scrapedmodel.find_all_by_retailer_id(ret)
       end
     end
     return sps
  end
  
  # --- Methods for mapping ScrapedPrinter <--> RetailerOffering (1 to many) --- #
  
  def find_ros_from_scraped sp, model=$model
    ros = RetailerOffering.find_all_by_local_id_and_retailer_id(sp.local_id, sp.retailer_id)
    return ros.reject{|x| x.product_type != $model.name}
  end
  
  def link_ro_and_sp ro, sp
    local_id = ro.local_id || sp.local_id
    retailer_id = ro.retailer_id || sp.retailer_id
    if local_id.nil? or retailer_id.nil?
      report_error "Couldn't link RO #{ro.id} and SP #{sp.id}"
      return false 
    end
    [ro,sp].each{|x| 
        fill_in 'local_id', local_id, x
        fill_in 'retailer_id', retailer_id, x
    }
    return true
  end
  
  def find_sp_from_ro ro
    return find_sp ro.local_id, ro.retailer_id
  end
  
  def find_ros_from_sp sp
    return find_ros(sp.local_id, sp.retailer_id)
  end
  
  def find_sp local_id, retailer_id
    return ScrapedPrinter.find_all_by_local_id_and_retailer_id(local_id, retailer_id).first
  end
  
  def find_ros local_id, retailer_id
    return RetailerOffering.find_all_by_local_id_and_retailer_id(local_id, retailer_id)
  end
  
  def recognize_review(atthash)
    revu = nil
    # Try finding review by review ID (and retailer ID?)
    if atthash['local_review_id'] #and atthash['retailer_id']
      revu = Review.find_all_by_local_review_idand_product_type(atthash['local_review_id'], $model.name).first
    end
    if revu.nil? and atthash['local_id'] and atthash['customerid']
      revu = Review.find_all_by_local_id_and_customerid_and_product_type(atthash['local_id'],\
          atthash['customerid'], $model.name).first
    end 
    if revu.nil? and atthash['content']
      # find by content...
      revu = Review.find_all_by_content(atthash['content']).reject{ |x| 
        !x.local_id.nil? and !atthash['local_id'].nil? and atthash['local_id'] != !x.local_id
      }.first
    end    
    return revu
  end
  
  def is_revue_recognizable? atthash
    return true if atthash['local_review_id']
    return true if atthash['local_id'] and atthash['customerid']
    return true if atthash['content'] and atthash['content'].length > 50 # kinda arbitrary...
    return false
  end
  
  # Tries to make sure that duplicate reviews aren't recorded.
  # Has several matching 
  def find_or_create_review(atthash)
    revu = recognize_review(atthash)
    if revu.nil?
       if is_revue_recognizable? atthash
         revu = create_product_from_atts atthash, Review
       end
    end
    return revu
  end
  
end