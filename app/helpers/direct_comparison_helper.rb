module DirectComparisonHelper
  def IsPresentAndUniqueInCSV(item, csvString)
    # Parse csv string into array
    # match item with each element of array, and return true if match occurs
    values = csvString.to_s.split(',')
    return false if values.length > 1 # If 2 or more items have the best value
    return true if !values.index(item.to_s).nil?
    return false
  end
  
  def box_width
    case @products.size
    when 4
      900
    when 3
      709
    else
      518
    end
  end
end
