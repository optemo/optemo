module DatabaseHelper
  
  $general_ignore_list = ['id','created_at','updated_at']
  
  # Should return itself and any other matching printers.
  def match_printer_to_printer ptr  
    makes = [nofunnychars(ptr.brand)].delete_if{ |x| x.nil? or x == ""}
    modelnames = [nofunnychars(ptr.model),nofunnychars(ptr.mpn)].delete_if{ |x| x.nil? or x == ""}
    
    return match_rec_to_printer makes, modelnames
  end
  
  def match_rec_to_printer rec_makes, modelnames
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
    
    Printer.all.each do |ptr|
      p_makes = [nofunnychars(ptr.brand)].delete_if{ |x| x.nil? or x == ""}
      p_modelnames = [nofunnychars(ptr.model),nofunnychars(ptr.mpn)].delete_if{ |x| x.nil? or x == ""}

      matching << ptr unless ( (p_makes & makes).empty? or (p_modelnames & modelnames).empty? )
    end
    return matching
  end
  
  def create_printer rec
    atts_to_copy = only_overlapping_atts rec.attributes, $model
    p = Printer.new(atts_to_copy)
    p.save
    return p
  end
  
  def update_bestoffer p
    matching_ro = RetailerOffering.find_all_by_product_id_and_product_type(p.id,$model.name).delete_if{ |x| 
      x.stock == false or x.priceint.nil?
    }
    return if matching_ro.empty?
    
    lowest = matching_ro.sort{ |x,y|
      x.priceint <=> y.priceint
    }.first
    
    fill_in 'bestoffer', lowest.id, p
    fill_in 'price', lowest.priceint, p
    fill_in 'pricestr', lowest.pricestr, p
    fill_in 'instock', true, p
  end
  
  def only_overlapping_atts atts, other_recs_class, ignore_list=[]
    big_ignore_list = ignore_list + $general_ignore_list
    overlapping_atts = atts.delete_if{ |x,y| 
      y.nil? or not other_recs_class.column_names.include? x \
      or big_ignore_list.include? x }
    return overlapping_atts
  end
  
end