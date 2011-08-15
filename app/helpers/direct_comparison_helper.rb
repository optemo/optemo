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
    (@products.size - 2) * 201 + 531
    531 if @products.size <= 2
  end
  # Sort features of specs in compare page: if they are also filter features following same order of filters, otherwise give it large number (eg: 9999)
  def sort_show_feats
    feats=Session.continuous['show'].map{|x| {x=>'cont'}} + Session.categorical['show'].map{|x| {x=>'cat'}} + Session.binary['show'].map{|x| {x=>'bin'}}
    feats.sort! do |a,b|
      a_index = Session.filters_order.index{|f| f[:name]==a.keys[0]}
      b_index = Session.filters_order.index{|f| f[:name]==b.keys[0]}
      (a_index.nil? ? 9999 : Session.filters_order[a_index][:show_order].to_i) <=>(b_index.nil? ? 9999 : Session.filters_order[b_index][:show_order].to_i)
    end
    feats
  end
end
