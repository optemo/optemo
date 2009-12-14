# Methods for the database.
# Note: for more update methods see fillin_helper.rb
module DatabaseHelper

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
  
  
end