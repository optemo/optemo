module ReviewsHelper
  
  # TODO This might not work as expected!
  def recognize_review(atthash)
    revu = nil
    # Try finding review by review ID (and retailer ID?)
    if atthash['local_review_id'] #and atthash['retailer_id']
      revu = Review.find_all_by_local_review_idand_product_type(atthash['local_review_id'], Session.product_type).first
    end
    if revu.nil? and atthash['local_id'] and atthash['customerid']
      revu = Review.find_all_by_local_id_and_customerid_and_product_type(atthash['local_id'],\
          atthash['customerid'], Session.product_type).first
    end 
    # TODO Check that matching by content is ok...
    if revu.nil? and atthash['content']
      # find by content...
      revu = Review.find_all_by_content(atthash['content']).reject{ |x| 
        !x.local_id.nil? and !atthash['local_id'].nil? and atthash['local_id'] != !x.local_id
      }.first
      debugger if revu
    end
    return revu
  end
  
  # Tries to make sure that duplicate reviews aren't recorded.
  # Has several matching 
  def find_or_create_review(atthash)
    revu = recognize_review(atthash)
    if revu.nil?
      #debugger
      revu = Review.new(atthash)
    end
    return revu
  end
  
  # Can this review be identified?
  def review_is_recognizable? revu
    # Try finding review by review ID (and retailer ID?)
    return false unless revu['retailer_id']
    return true if revu['local_review_id'] 
    return true if revu['local_id'] and revu['customerid']
    return false
  end
  
end