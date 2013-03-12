class Categorical < Facet
  def display_colours
    return [] unless name == "color"
    color_counts = CatSpec.count_feat("color")
    display_colours = %w(red orange yellow green blue purple pink white silver brown black).zip(
       %w(l   l       l       d   d     d     l     l     l     d     d    ))
    display_colours.select{|color,b| !!selected.index{|x| x.value == color && x.name == "color"} or !color_counts[color].nil?}
  end
  
  def no_display
    if name == "color"
      display_colours.empty?
    else
      !optionlist.to_a.inject(false){|res,(k,v)| res || v > 0} #Don't display if there are no counts
    end
  end
  
  def expanded
    Session.search.expanded.try{|b| b.include?(name)}
  end
  
  def selected
    Session.search.userdatacats.select{|d|d.name == name}
  end
  
  def optionlist
    optionlist = feat_counts
    if name == "product_type"
      optionlist = {}
      product_type = Session.landing_page
      children = ProductCategory.get_subcategories(product_type)
      leaves = CatSpec.count_feat(name)
      children.each do |fp|
        l = ProductCategory.get_leaves(fp)
        optionlist[fp] = l.map{|e| leaves[e]}.compact.inject(0){|res,ele| res+ele}
      end
      if children.empty?
        leaf_type = Session.product_type
        optionlist[leaf_type] = leaves[leaf_type]
      end
      optionlist
    elsif !custom_order.empty? #Order based on the ordering in the facet table
      optionlist = optionlist_with_partial_order(optionlist, custom_order)
    elsif alphabetical
      optionlist = Hash[*optionlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
    else #Count-based ordering
      optionlist #already sorted by counts from SOLR
    end
  end
  
  def toplist
    if name == "product_type"
      optionlist #Should not display More/Less
    else
      optionlist = feat_counts #Sorted by counts
      unless custom_order.empty? #Order based on the ordering in the facet table
        optionlist = optionlist_with_partial_order(optionlist, custom_order) 
      end
      optionlist.keys[0..(topcount-1)]
    end
  end
  
  private
  
  def feat_counts
    @feat_counts ||= CatSpec.count_feat(name)
  end
  
  def optionlist_with_partial_order(optionlist, order)
    listed = optionlist.to_a.select{|k,v| !order[k].nil?}.sort{|a,b| order[a[0]] <=> order[b[0]]}
    not_listed = optionlist.to_a.select{|k,v| order[k].nil?}
    optionlist = Hash[*(listed + not_listed).flatten]
  end
  
  def custom_order
    if @custom_order
      @custom_order
    else
      q = Facet.where(feature_type: "Ordering", product_type: product_type, used_for: name)
      @custom_order = CachingMemcached.cache_lookup("CatOrder#{q.to_sql}") do
        q.inject({}){|h,f| h[f.name] = f.value; h}
      end
    end
  end
  
  def alphabetical
    %w(brand).include? name
  end
  
  def topcount #The number of objects in the topcount
    case name
    when "brand" then 10
    else 6
    end
  end
end