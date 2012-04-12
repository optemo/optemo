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

  def getRanges(feat, cats)
    num_ranges = 6
    Ranges.cacherange(feat, num_ranges, cats)
  end  

  def getLeafs
    leafs = Session.search.userdatacats.map{|d| d.value if d.name=="product_type"}.compact
    leafs.empty? ?  "" : leafs.join
  end  
  
	def getDist(feat)
    num_buckets = 24
    discretized = Session.search.solr_cached.facet(feat.to_sym).rows
    if (!discretized.empty?)
      min_all = Rails.cache.fetch("Min#{Session.search.keyword_search}#{Session.product_type}#{feat}") {discretized.first.value}
      max_all = Rails.cache.fetch("Max#{Session.search.keyword_search}#{Session.product_type}#{feat}") {discretized.last.value}
    
      min = discretized.first.value
      max = discretized.last.value
      step = (max - min + 0.00000001) / num_buckets
      dist = Array.new(num_buckets,0)
      #Bucket the data
      discretized.each do |r|
        dist[((r.value-min) / step).floor] += r.count
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
    ranges.each_with_index do |r, ind|
      dr << {:count => Ranges.count(feat, r[:min], r[:max]), :min => r[:min], :max => r[:max], :display => ""}
      if dr.last[:count] >0 
        if r[:min] == r[:max] 
         if feat == "saleprice" && I18n.locale == :en
           dis = "$#{r[:min]}"
         else
           dis =  "#{r[:min]} " + t("#{Session.product_type}.filter.#{feat}.unit") 
         end   
        else
          if feat == "saleprice" && I18n.locale == :en
            dis = "$#{r[:min]} - $#{r[:max]}"
          else
            dis = "#{r[:min]} "+t("#{Session.product_type}.filter.#{feat}.unit")  +" - #{r[:max]} " + t("#{Session.product_type}.filter.#{feat}.unit")
          end    
        end 
        dr.last[:display] << dis  
      end  
    end   
    dr = dr.select{|d| d[:count]>0}
    unless dr.empty?
      if feat == "saleprice" && I18n.locale == :en
         dr.first[:display] = "Below $#{dr.first[:max]}"
         dr.last[:display] = "$#{dr.last[:min]} and above"
      else    
         dr.first[:display] = "#{dr.first[:max]}" + t("#{Session.product_type}.filter.#{feat}.unit") + " and below"
         dr.last[:display] = "#{dr.last[:min]}"+ t("#{Session.product_type}.filter.#{feat}.unit")+ " and above"
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
    longlist = {}
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
        longlist = CatSpec.count_feat(f.name)
        if longlist.length > 10
          optionlist = Hash[*longlist.to_a[0..9].sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
          longlist = Hash[*longlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
        else
          optionlist = Hash[*longlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
          longlist = {}
        end
        
      else
        optionlist = CatSpec.count_feat(f.name)
        #optionlist = CatSpec.count_feat(f.name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
        order = CatSpec.order(f.name)
        unless order.empty?
          optionlist = optionlist.to_a.sort{|a,b| order[a[0]] <=> order[b[0]] } 
        end
      end
    end
    [optionlist, longlist]
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
      content_tag("div","",class: "imageholder")
    else
      image_tag product.image_url(size), :class => size == :medium ? "productimg" : "", alt: "", :'data-id' => product.id, :'data-sku' => product.sku, :onerror => "javascript:this.onerror='';this.src='#{product.image_url(:large)}';return true;", width: "150px", height: "150px"
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
