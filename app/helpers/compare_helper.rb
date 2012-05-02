module CompareHelper
  def main_boxes
    res = []
    Session.search.paginated_products.map{|p|Product.cached(p.id)}.each_slice(3) do |box1,box2,box3|
      res << content_tag("div", :style => "padding: 10px 0") do
        content_tag("div", :class => "row_bounding_box") do
          navbox_content = render(:partial => 'navbox', :locals => {product: box1, last_in_row: false}) +
          render(:partial => 'navbox', :locals => {product: box2, last_in_row: false}) +
          render(:partial => 'navbox', :locals => {product: box3, last_in_row: true}) +
          content_tag(:div, raw("<!-- -->"), class: 'navbox_grey_separator_image_left') +
          content_tag(:div, raw("<!-- -->"), class: 'navbox_grey_separator_image_right')
          if !box1.product_bundles.empty? || (box2 && !box2.product_bundles.empty?) || (box3 && !box3.product_bundles.empty?)
            navbox_content += render(:partial => 'bundle', :locals => {product: box1, last_in_row: false}) +
            render(:partial => 'bundle', :locals => {product: box2, last_in_row: false}) +
            render(:partial => 'bundle', :locals => {product: box3, last_in_row: true})
          else
            navbox_content
          end
        end
      end
    end
    res.join(content_tag("div", raw("<!-- -->"), class: "divider"))
  end

  def product_title
    if I18n.locale == :fr
      t("#{Session.product_type}.name")
    else
      Session.search.products_size > 1 ? t("#{Session.product_type}.name").pluralize : t("#{Session.product_type}.name")
    end
  end
 
  def chosencats(feat)
    (Session.search.userdatacats+Session.search.parentcats).select{|d|d.name == feat}.map{|x|x.value}
  end
  
  def chosenconts(feat)
    c = []
    (Session.search.userdataconts+Session.search.parentconts).select{|d| d.name == feat}.each{|x| c << {:min => x[:min], :max => x[:max]}}  
    c
  end  

  def showSelectedRanges(values, name)
    displayRanges(name, getRanges(name)).select{|r| !values.select{|v| v.min == r[:min]}.empty? }
  end

  def spec_type(spec)
    ret = nil
    case 
    when spec.class == Userdatacont
      ret = 'continuous'
    when spec.class == Userdatacat
      ret = 'categorical'
    when spec.class == Userdatabin
      ret = 'binary'
    when spec.class == Facet
      ret = 'facet'
    end
    ret
  end

  def getSearchFilters()
    # getting the currently applied filters
    filters = Session.search.userdataconts + Session.search.userdatacats + Session.search.userdatabins
    if filters.empty?
      return []
    end
    # grouping by facet name
    grouped = {}
    filters.each do |fs|
      name = fs.name
      if grouped.has_key?(name)
        grouped[name] << fs 
      else
        grouped[name] = [fs]
      end
    end
    # make the filter facets grouped by name into a list sorted by the order of each facet
    sorted = grouped.sort_by {|name, v| Facet.find_by_name_and_product_type_and_used_for(name, Session.product_type, 'filter').value }
    
    # add ordering
    # FIXME: make page_order into a hash by name
    page_order = Session.features['filter'].map{ |f| {:name => f.name, :feature_type => f.feature_type, :value => f.value, :printed => false} }
    new_sorted = []
    sorted.each do |name, values|
      new_group = {name => []}
      values.each do |v|
        item = page_order.select{|f| f[:name] == name}[0] # this possibly can be optimized
        if item[:feature_type] == 'Binary'
          past_headings = page_order.select{|f| f[:value] < item[:value] and f[:feature_type] == 'Heading'}
          if !past_headings.empty? and past_headings.last[:printed] == false
            past_headings.last[:printed] = true
            new_group[name] << Session.features['filter'].select{ |f|f.name == past_headings.last[:name] }.first
          end
        end
        new_group[name] << v
      end
      new_sorted << [name, new_group[name]]
    end
    # Possible extension: also order the values within each 'name', i.e. the different categorical values of each facet
    new_sorted
  end
  
  def displaySelectedString(spec)
    if spec.instance_of?(Userdatabin)
      spec.name
    elsif spec.instance_of?(Userdatacat)
      spec.value
    elsif spec.instance_of?(Userdatacont)
      spec.min.to_s + ' to ' + spec.max.to_s
    end
  end

  def getRanges(feat)
    num_ranges = 6
    cats = Session.search.userdatacats.map{|d| d if d.name=="product_type"}.compact
    #debugger if Ranges.cacherange(Session.product_type, num_ranges, cats)[feat.to_sym].nil?
    feats = Session.features["filter"].map{|f| f.name if f.feature_type=="Continuous" && f.ui=="ranges"}.compact
    Ranges.cacherange(feats, num_ranges, cats)[feat.to_sym]
  end  
  
	def getDist(feat)
    num_buckets = 24
    discretized = Session.search.solr_cached.facet(feat.to_sym).rows
    if (!discretized.empty?)
      min_all = Rails.cache.fetch("Min#{Session.search.keyword_search}#{Session.product_type}#{feat}") {discretized.first.value}
      max_all = Rails.cache.fetch("Max#{Session.search.keyword_search}#{Session.product_type}#{feat}") {discretized.last.value}
      saved_cont = Session.search.userdataconts.select{|m|m.name == feat}.first      
      if saved_cont.nil?
        min = discretized.first.value
        max = discretized.last.value
      else
        min = saved_cont.min
        max = saved_cont.max
      end
      step = (max_all - min_all + 0.00000001) / num_buckets
      dist = Array.new(num_buckets,0)
      #Bucket the data
      dist.each_with_index do |bucket,i|
        low = min_all + step * i
        high = low + step
        sum = 0
        if (min..max) === low or (min..max) === high
          sum = discretized.select{|p| (low..high)===p.value and (min..max)===p.value }.inject(0){|res,ele| res+ele.count}
        end
        dist[i] = sum
      end
      #Normalize to a max of 1
      maxval = dist.max
      dist.map!{|i| i.to_f / maxval}
      [[min,max]+[min_all,max_all],dist]
    else
      []
    end
  end

  def displayRanges(feat, ranges)
    dr = []
    unless ranges.nil?
      ranges.each_with_index do |r, ind|
        dr << {:count => Ranges.count(feat, r[:min], r[:max]), :min => r[:min], :max => r[:max], :display => ""}
        if dr.last[:count] >0 
          if r[:min] == r[:max]
            if feat == "saleprice"
              dis = number_to_currency(r[:min])
            else
              dis =  "#{r[:min]} " + t("#{Session.product_type}.filter.#{feat}.unit") 
            end
          else
            if feat == "saleprice"
              dis = number_to_currency(r[:min]) + " - " + number_to_currency(r[:max])              
            else
              dis = "#{r[:min]} "+t("#{Session.product_type}.filter.#{feat}.unit")  +" - #{r[:max]} " + t("#{Session.product_type}.filter.#{feat}.unit")
            end    
          end 
          dr.last[:display] << dis
        end
      end   
    end  
    dr = dr.select{|d| d[:count]>0}
    unless dr.empty?
      if feat == "saleprice"
         dr.first[:display] = (dr.first[:max] > 0 ? t("features.belowbefore") : '') + number_to_currency(dr.first[:max])
         dr.last[:display] = number_to_currency(dr.last[:min]) + t("features.rangeabove")
      else
         dr.first[:display] = "#{dr.first[:max]} " + t("#{Session.product_type}.filter.#{feat}.unit") + (dr.first[:max] > 0 ? t("features.rangebelow") : "")
         dr.last[:display] = "#{dr.last[:min]} "+ t("#{Session.product_type}.filter.#{feat}.unit")+ t("features.rangeabove")
      end
    end
    dr
  end

  def missing_spec_name_translation?(name)
    missing = false
    begin
      I18n::translate(Session.product_type + ".specs." + name + ".name", :raise => true)
    rescue I18n::MissingTranslationData
      missing = true
    end
    missing
  end
  
  def sortby
    current_sorting_option = Session.search.sortby || "utility_desc"
    sortby_f = Session.features["sortby"].reject{|f| f.name== "lr_utility"}
    sortby_f.map do |f| 
        suffix = f.style.length > 0 ? '_' + f.style : ''
        content_tag :li, (current_sorting_option == (f.name+suffix)) ? t(Session.product_type+".sortby."+f.name+suffix+".name") : link_to(t(Session.product_type+".sortby."+f.name+suffix+".name"), "#", {:'data-feat'=>f.name+suffix, :class=>"sortby"})
    end.join(content_tag(:span, raw("&nbsp;&nbsp;|&nbsp;&nbsp;"), :class => "seperator"))    
  end
  
  def stars(numstars)
    fullstars = numstars.to_i
    halfstar = (fullstars == numstars) ? 0 : 1
    emptystars = 5 - fullstars - halfstar
    ret = ""
    fullstars.times do
      ret += '<div class="ratingStar"><!-- --></div> '
    end
    halfstar.times do
      ret += '<div class="ratingHalfStar"><!-- --></div>'
    end
    emptystars.times do
      ret += '<div class="ratingEmptyStar"><!-- --></div>'
    end
    ret += "&nbsp;" + numstars.to_s + " /5" if Session.futureshop?
    return ret
  end
  
  def cat_order(f, chosen_cats, tree_level= 1)
    optionlist={}
    toplist = []
    if (request.host =="keyword")
       if f.name == "product_type"
       #IMPLEMENTATION WITHOUT INDEXING THE FIRST AND SECOND ANCESTORS
       #  leaves = CatSpec.count_feat(f.name)
       # # puts "leaves_compare #{leaves}"
       #  (ProductCategory.get_ancestors(leaves.keys, tree_level)+leaves.keys).each do |fp|
       #    l = ProductCategory.get_leaves(fp)
       #   # puts "first_ancestor #{fp} its leaves #{l}"
       #    optionlist[fp] = l.map{|e| leaves[e]}.compact.inject{|res,ele| res+ ele}
       #  end
       #***************
        templist = CatSpec.count_feat(f.name, tree_level)
         puts "optionlist_test #{templist}"
        optionlist = process_product_type_hash(templist)
        
       else
        optionlist = CatSpec.count_feat(f.name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
       end
    else
      if f.name == "product_type"
        optionlist = {}
        children = ProductCategory.get_subcategories(Session.product_type)
        leaves = CatSpec.count_feat(f.name)
        children.each do |fp|
          l = ProductCategory.get_leaves(fp)          
          optionlist[fp] = l.map{|e| leaves[e]}.compact.inject(0){|res,ele| res+ele}
        end
      elsif f.name == "brand" # To ensure alphabetical sorting (regardless of capitalization)
        optionlist = CatSpec.count_feat(f.name)
        if optionlist.length > 10
          toplist = optionlist.keys[0..9]
        end
        optionlist = Hash[*optionlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
      else
        # Check if the feature has translations
        if I18n.t("cat_option.#{f.name}", :default => '').empty?
          optionlist = CatSpec.count_feat(f.name)
          #optionlist = CatSpec.count_feat(f.name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
          order = CatSpec.order(f.name)
        else #Need to downcase the keys so that they match
          order = {}
          CatSpec.order(f.name).each {|a,b| order[a.downcase] = b}
          # Take this out when the specs/translations difference has been sorted out for all products
            optionlist = {}
            CatSpec.count_feat(f.name).each {|a,b| optionlist[a.downcase] = b}
        end   
        unless order.empty?
          optionlist = optionlist.to_a.sort{|a,b| order[a[0]] <=> order[b[0]] } 
        end
      end
    end
    [optionlist, toplist]
  end
 
  def sub_level(product_type, tree_level= 2)
    optionlist={}
   #IMPLEMENTATION WITHOUT INDEXING THE FIRST AND SECOND ANCESTORS
   # leaves = CatSpec.count_feat("product_type")
   # ancestors = ProductCategory.get_ancestors(leaves.keys, tree_level) + leaves.keys
   # subcategories = ProductCategory.get_subcategories(product_type).each do |sub|
   #    if ancestors.include?(sub)
   #     optionlist[sub] =  ProductCategory.get_leaves(sub).map{|e| leaves[e]}.compact.inject{|res,ele| res+ ele}
   #    end
   # end
   #puts "sub_level #{ancestors} #{subcategories}"
   #****************
    temp_ancestors = CatSpec.count_feat("product_type",tree_level)
    second_ancestors = process_product_type_hash(temp_ancestors)
    
    subcategories = ProductCategory.get_subcategories(product_type).each do |sub|
      if second_ancestors.has_key?(sub) && second_ancestors[sub]>0
        optionlist[sub] = second_ancestors[sub]
      end
    end
    puts"sub_levels #{optionlist}"
    optionlist
  end
  
  def process_product_type_hash(list)
    ret_list={}
    list.each do |e,k|
      if (e[0] =='B')
        e= 'B'+ (e.split("B"))[1]
      elsif 
        e = 'F'+(e.split('F'))[1]
      end
       if ret_list[e] 
         ret_list[e]+= k 
       else
         ret_list[e] = k 
       end
    end
    ret_list
  end
  
  def only_if_onsale(product)
    'style="display:none;"' unless BinSpec.cache_all(product.id)["onsale"]
  end
  
  def only_if_not_onsale(product)
    'style="display:none;"' if BinSpec.cache_all(product.id)["onsale"]
  end
  
  def calcInterval(min,max)
    range = max - min
    interval = 0
    [1000, 500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01].each do |s|
      interval = s
      break if range/s > 30 #30 was selected arbitrarly, so that it looks good in the sliders
    end
    interval
  end
  
  def roundedInterval(val,interval,down = true)
    if down
      (val/interval).floor*interval
    else
      (val/interval).ceil*interval
    end
  end
  
  def product_type_link(type,name)
    if (type == Session.product_type)
      content_tag("b", name)
    else
      link_to name, "?category_id=#{type}" 
    end
  end
  
  def product_image(product,size)
    if BinSpec.find_by_product_id_and_name(product.id, "missingImage")
      #Load missing image placeholder
      content_tag(:div, "", :class => "imageholder", :'data-sku' => product.sku, :'data-id' => product.id)      
    else
      image_tag product.image_url(size), :class => size == :medium ? "productimg" : "", alt: "", :'data-id' => product.id, :'data-sku' => product.sku, :onerror => "javascript:this.onerror='';this.src='#{product.image_url(:large)}';return true;"
    end
  end
end

module WillPaginate
  module ViewHelpers
    def page_entries_info(collection, options = {})
      entry_name = options[:entry_name] ||
        (collection.empty? ? 'entry' :
          collection.first.class.name.underscore.sub('_', ' '))
      if Session.futureshop?
        t('will_paginate.page_entries_info.futureshop_multi_page_html', :current_page => collection.current_page, :total_pages => collection.total_pages)
      else # Best Buy
        t('will_paginate.page_entries_info.multi_page_html', :from => collection.offset + 1, :to => collection.offset + collection.length, :count => collection.total_entries)
      end
    end
  end
end
