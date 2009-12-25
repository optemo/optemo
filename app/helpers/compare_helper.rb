module ContentHelper
end

module CompareHelper
  def finalDisplay(product, column)
    case column
      when 'itemdimensions'
        return product.display('itemlength').chop.chop + " X " + product.display('itemwidth').chop.chop + " X " + product.display('itemheight').chop.chop + " cm"
      when 'packagedimensions'
      	return product.display('packagelength') + " x " + product.display('packagewidth') + " x " + product.display('packageheight')
      when 'price'
        return product.display('pricestr')
#      when 'opticalzoom', 'digitalzoom'
#        return '-' if product.bodyonly
    end
    case product.display(column)
      # Display Unavailable instead of Unknown
      when 'Unknown' 
        return "Unavailable"
      when "true"
        # return "&#10003;" # This is not IE6 compatible
        # To make it IE compatible, replace by-
        image_tag '/images/checkmark.png', :width => 18, :height => 18
        # But then need to do something to fade out image when row is faded
      when "false"
        return "x"		
      else
        return product.display(column)[0..20]
    end
  end
  
  def numberOfStars(utility)
   return ((utility*10).ceil)*0.5
  end
  
  def IsPresentAndUniqueInCSV(item, csvString)
    # Parse csv string into array
    # match item with each element of array, and return true if match occurs
    values = csvString.to_s.split(',')
    return false if values.length > 1 # If 2 or more items have the best value
    return true if !values.index(item.to_s).nil?
    return false
  end
  
end
