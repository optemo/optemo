module DatabaseHelper
  
  $general_ignore_list = ['id','created_at','updated_at']
  $region_suffixes = {'CA' => '_ca', 'US' => ''}
  
  # Should return itself and any other matching printers.
  def match_printer_to_printer ptr, recclass=$model  , series=[]
    makes = [just_alphanumeric(ptr.brand)].delete_if{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].delete_if{ |x| x.nil? or x == ""}
    
    return match_rec_to_printer makes, modelnames,recclass, series
  end
  
  def match_rec_to_printer rec_makes, rec_modelnames, recclass=$model, series=[]
    matching = []
    makes = rec_makes
    rec_makes.each do |make|
      # Stupid brand inconsistencies..
      if(make.include? 'oki')
        makes += ['oki', 'okidata']
      elsif(make.include?( 'hp') or make.include?( 'hewlett'))
        makes += ['hp','hewlettpackard']
      end
    end
    makes.uniq
    
    modelnames = rec_modelnames
    series.each { |ser| modelnames.each {|mn| mn.gsub!(/\s#{ser}\s/,'') }}
    
    recclass.all.each do |ptr|
      p_makes = [just_alphanumeric(ptr.brand)].delete_if{ |x| x.nil? or x == ""}
      p_modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].delete_if{ |x| x.nil? or x == ""}

      series.each { |ser| p_modelnames.each {|pmn| pmn.gsub!(/#{ser}/,'') } }

      matching << ptr unless ( (p_makes & makes).empty? or (p_modelnames & modelnames).empty? )
    end
    return matching
  end
  
  def create_product_from_atts atts, recclass=$model
    atts_to_copy = only_overlapping_atts atts, recclass
    p = recclass.new(atts_to_copy)
    p.save
    return p
  end
  
  def create_product_from_rec rec, recclass=$model
    return create_product_from_atts rec.attributes, recclass
  end
  
  def create_retailer_offering specific_o, product
    fill_in 'product_id', product.id, specific_o
    fill_in 'product_type', $model.name, specific_o
    if specific_o.offering_id.nil? # If no RetailerOffering is mapped to this brand-specific offering:
      o = create_product_from_atts specific_o.attributes, RetailerOffering
      fill_in 'offering_id', o.id, specific_o
    else
      o = RetailerOffering.find(specific_o.offering_id)
    end
    return o
  end
  
  def update_bestoffer p
    
    $region_suffixes.keys.each do |region|
      update_bestoffer_regional p, region
    end
    
  end
  
  def update_bestoffer_regional p, region
    matching_ro = RetailerOffering.find(:all, :conditions => \
      "product_id LIKE #{p.id} and product_type LIKE '#{$model.name}' and region LIKE #{region}").\
      reject{ |x| !x.instock or x.price.nil? }
    return if matching_ro.empty?
    
    lowest = matching_ro.sort{ |x,y|
      x.priceint <=> y.priceint
    }.first
    
    fill_in "bestoffer#{$region_suffixes[region]}", lowest.id, p
    fill_in "price#{$region_suffixes[region]}", lowest.priceint, p
    fill_in "pricestr#{$region_suffixes[region]}", lowest.pricestr, p
    fill_in "instock#{$region_suffixes[region]}", true, p
  end
  
  def only_overlapping_atts atts, other_recs_class, ignore_list=[]
    big_ignore_list = ignore_list + $general_ignore_list
    overlapping_atts = atts.delete_if{ |x,y| 
      y.nil? or not other_recs_class.column_names.include? x \
      or big_ignore_list.include? x }
    return overlapping_atts
  end
  
end