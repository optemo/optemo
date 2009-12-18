module Products
  
  # TODO
  def get_matching_sets_efficient recs=$model.all, series=[], brands=[]
     matchingsets = []
     recclass = recs.first.class
     data = recs.collect{|x| [x.id, x.model, x.mpn, x.brand]}
     data.each do |x|
       makes = [x[3]]
       modelnames = [x[1], x[2]]
       #matchingsets << (match_product_to_product rec, recclass, series).collect{|x| x.id}
       #matchingsets << (find_matching_product_efficient(makes, modelnames,recclass.all, series, brands)).collect{|x| x.id}
     end
     matchingsets.collect{|x| x.sort}.uniq
     return matchingsets
  end
  
  # Returns sets of IDs of records that match. eg
  # [[1,2], [3], [4,5,6]] means records with id 1 and 2
  # are the same product; 3 doesn't match any others,
  # just itself; and 4,5,and 6 are also the same product.
  # OK to used for any db model that can be compared 
  # by the brand, model, and mpn attributes.
  def get_matching_sets recs=$model.all, series=[]
     matchingsets = []
     recclass = recs.first.class
     recs.each do |rec|
       matchingsets << (match_product_to_product rec, recclass, series).collect{|x| x.id}
     end
     matchingsets.collect{|x| x.sort}.uniq
     return matchingsets
  end
  
  # Returns itself and any other matching products(or other specified model)
  def match_product_to_product ptr, recclass=$model, series=[]
    makes = [just_alphanumeric(ptr.brand)].reject{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].reject{ |x| x.nil? or x == ""}
    
    return find_matching_product makes, modelnames,recclass, series
  end
  # Finds a record of the given db model by 
  # possible make(aka brand) and model lists. 
  # Example: find_matching_product( ['HP','hewlett-packard'],  ['Q123xd',nil], product)
  # The series is used to clean the model name, in case you had "Phaser 100abc"
  # Then if you list "Phaser" in the series, it'll try to match "100abc" as the model name too.
  def find_matching_product rec_makes, rec_modelnames, recclass=$model, series=[]
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

  # TODO
  def find_matching_product_efficient rec_makes, rec_modelnames, recset, series=[], brands=$brands
    matching = []
    make = clean_brand(rec_makes * ", ", brands)
    modelnames = model_series_variations(rec_modelnames, series)
    data = recset.collect{|x| [x.id, x.model, x.mpn, x.brand] }
    data.each do |row|
      p_make = clean_brand(row[3], brands)
      p_modelnames = model_series_variations([row[1], row[2]], series)
      matching << row[0] unless ( p_make != make or (p_modelnames & modelnames).empty? )
    end
    return matching
  end  
  

end

