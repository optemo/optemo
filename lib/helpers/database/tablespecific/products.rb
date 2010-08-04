module ProductsHelper
  
  # TODO
  def get_matching_sets_efficient #, series=[], brands=[]
    matchingsets = []
    debugger
    .each do |p|
      # Some manufacturers use model, some use mpn, so we have to search on all combinations of [model, mpn] and combine them.
      # Then, remove the duplicates after taking a union of all the arrays.
      x = Product.find_all_by_brand_and_model(p.brand, p.model)
      y = Product.find_all_by_brand_and_mpn(p.brand, p.model)
      z = Product.find_all_by_brand_and_model(p.brand, p.mpn)
      w = Product.find_all_by_brand_and_mpn(p.brand, p.mpn)
      dups = (x | y | z | w).uniq.collect{|dup| dup.id}.sort
      if dups.length > 1
        if matchingsets.last and matchingsets.last[0] == dups[0]
          temp = (matchingsets.last | dups).sort.uniq
          matchingsets.pop
          matchingsets << dups
        else
          matchingsets << dups unless matchingsets.include?(dups)
        end
      end
    end
    matchingsets
  end
  
  # Returns sets of IDs of records that match. eg
  # [[1,2], [3], [4,5,6]] means records with id 1 and 2
  # are the same product; 3 doesn't match any others,
  # just itself; and 4,5,and 6 are also the same product.
  # OK to used for any db model that can be compared 
  # by the brand, model, and mpn attributes.
  def get_matching_sets recs=Product.find(:all, :conditions => ["product_type=?",Session.current.product_type]), series=[]
     matchingsets = []
     # Check other get_matching_sets
     recs.each do |rec|
       matchingsets << (match_product_to_product(rec, recs, series)).collect{|x| x.id}
     end
     return matchingsets.collect{|x| x.sort}.uniq
     # return matchingsets # This can't possibly be intentional, it seems like the array is modified and then the modification not used.
  end

  # Returns itself and any other matching products(or other specified model)
  def match_product_to_product(ptr, products, series = [])
    makes = [just_alphanumeric(ptr.brand)].reject{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].reject{ |x| x.nil? or x == ""}
    return find_matching_product(makes, modelnames, products, series)
  end

  # Finds a record of the given db model by 
  # possible make(aka brand) and model lists. 
  # Example: find_matching_product( ['HP','hewlett-packard'],  ['Q123xd',nil])
  # The series is used to clean the model name, in case you had "Phaser 100abc"
  # Then if you list "Phaser" in the series, it'll try to match "100abc" as the model name too.
  def find_matching_product(rec_makes, rec_modelnames, products, series=[])
    matching = []
    makes = rec_makes.collect{ |x| just_alphanumeric(x) }.reject(&:blank?)
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
    debugger
    # This is not efficient.
    products.each do |ptr|
      p_makes = [just_alphanumeric(ptr.brand)].reject(&:blank?)
      p_modelnames = [just_alphanumeric(ptr.model), just_alphanumeric(ptr.mpn)].reject(&:blank?)
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

