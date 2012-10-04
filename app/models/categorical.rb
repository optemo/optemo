class Categorical < Facet
  def display_colours
    return [] unless name == "color"
    color_counts = CatSpec.count_feat("color")
    display_colours = %w(red orange yellow green blue purple pink white silver brown black).zip(
       %w(l   l       l       d   d     d     l     l     l     d     d    ))
    display_colours.select!{|color,b| !!selected.index{|x| x.value == color && x.name == "color"} or !color_counts[color].nil?}
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
    (Session.search.userdatacats+Session.search.parentcats).select{|d|d.name == name}
  end
  
  def optionlist
    cat_order(selected.map{|x|x.value}).first
  end
  
  def toplist
    cat_order(selected.map{|x|x.value}).second
  end
  
  private
  
  def cat_order(chosen_cats, tree_level=1)
    optionlist={}
    toplist = []
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
    elsif name == "brand" # To ensure alphabetical sorting (regardless of capitalization)
      optionlist = CatSpec.count_feat(name)
      chosen_cats.each{|c| optionlist[c] = 0 unless optionlist.has_key?(c)}
      if optionlist.length > 10
        toplist = optionlist.keys[0..9]
      end
      optionlist = Hash[*optionlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
    else
      # Check if the feature has translations
      if I18n.t("cat_option.#{name}", :default => '').empty?
        optionlist = CatSpec.count_feat(name)
        chosen_cats.each{|c| optionlist[c] = 0 unless optionlist.has_key?(c)}
        if optionlist.length > 10
          toplist = optionlist.keys[0..9]
        end
        optionlist = Hash[*optionlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
      elsif name == "processorType" && Session.retailer == 'F'
        optionlist = CatSpec.count_feat(name)
        order = CatSpec.order(name)
        chosen_cats.each{|c| optionlist[c] = 0 unless optionlist.has_key?(c)}
        if optionlist.length > 6
          toplist = order.keys[0..5]
        end
        # for all elements in optionlist and not in order, add them to order with index > last
        listed = optionlist.to_a.select{|k,v| !order[k].nil?}.sort{|a,b| order[a[0]] <=> order[b[0]] }
        not_listed = optionlist.to_a.select{|k,v| order[k].nil?}
        optionlist = Hash[*(listed + not_listed).flatten]
      else
        # Check if the feature has translations
        if I18n.t("cat_option.#{name}", :default => '').empty?
          optionlist = CatSpec.count_feat(name)
          #optionlist = CatSpec.count_feat(name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
          order = CatSpec.order(name)
        else #Need to downcase the keys so that they match
          order = {}
          CatSpec.order(name).each {|a,b| order[a.downcase] = b}
          # Take this out when the specs/translations difference has been sorted out for all products
          optionlist = {}
          CatSpec.count_feat(name).each {|a,b| optionlist[a.downcase] = b}
        end
        unless order.empty?
          optionlist = Hash[*optionlist.to_a.sort{|a,b| order[a[0]] <=> order[b[0]] }.flatten]
        end
      end
    end
    [optionlist, toplist]
  end
end