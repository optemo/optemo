module CompareHelper
  def main_boxes
    res = []
    Session.search.paginated_products.each_slice(3) do |box1,box2,box3|
      res << content_tag("div", :style => "padding: 10px 0") do
        content_tag("div", :class => "row_bounding_box") do
          navbox_content = render(:partial => 'navbox', :locals => {product: box1}) +
          render(:partial => 'navbox', :locals => {product: box2}) +
          render(:partial => 'navbox', :locals => {product: box3}) +
          content_tag(:div, raw("<!-- -->"), class: 'navbox_grey_separator_image_left') +
          content_tag(:div, raw("<!-- -->"), class: 'navbox_grey_separator_image_right')
          if !box1.bundles_cached.empty? || (box2 && !box2.bundles_cached.empty?) || (box3 && !box3.bundles_cached.empty?)
            navbox_content += render(:partial => 'bundle', :locals => {product: box1}) +
            render(:partial => 'bundle', :locals => {product: box2}) +
            render(:partial => 'bundle', :locals => {product: box3})
          else
            navbox_content
          end
        end
      end
    end
    res.join(content_tag("div", raw("<!-- -->"), class: "divider"))
  end
  
  def get_active_features()
    # Go over all the filter features and determine how they should be displayed
    # returns an array, one hash element per feature to display 
    active_features = []
    # TODO: factor getting the selected cats and conts once up here instead of doing it per feature
    (Session.features["filter"] || []).each_with_index do |f, index|
      res = {}
      case f.feature_type
      when "Heading"
        # add f to features
      when "Categorical"
        chosen_cats = chosencats(f.name)
        if f.name == "color"
          res = getColorFeature(f, chosen_cats)
        else
          res = getCategoricalFeature(f, chosen_cats)
        end
      when "Continuous"
        chosen_conts = chosenconts(f.name)
        if f.ui == "ranges"
          res = getDisplayedRanges(f, chosen_conts)
        else
          res = getContinuousDistribution(f)
        end
      when "Binary"
        res = getBinaryFeature(f)
      end
      res[:f] = f
      active_features << res unless res[:no_display]
    end
    display_features = []
    # get rid of the elements which are headings that have nothing logically under them
    active_features.each_with_index do |feature, index|
      if feature[:f][:feature_type] == 'Heading'
        next_feature = active_features[index+1]
        unless next_feature.nil?
          next_feature_type = next_feature[:f][:feature_type]
          case next_feature_type
          when 'Binary'
              display_features << feature
          when 'Heading'
            unless active_features[index+2].nil?
              if feature[:f][:style] != '' and next_feature[:f].style == ''
                display_features << feature
              elsif feature[:f][:style] == '' and next_feature[:f].style != ''
                  display_features << feature
              end
            end
          else # when 'Categorical', 'Continuous'
            next
          end
        end
      else
        display_features << feature
      end
    end
    display_features
  end
  
  def getCategoricalFeature(f, chosen_cats)
    optionlist, toplist = cat_order(f, chosen_cats)
    if f.name == "brand" && @t
      brand_keys = Translation.cache_brands(optionlist.keys)
      @t.merge!(brand_keys) # merge two hashes
    end
    expanded = Session.search.expanded.try{|b| b.include?(f.name)}
    no_display = !optionlist.to_a.inject(false){|res,(k,v)| res || v > 0} #Don't display if there are no counts
    return {:all_options => optionlist, :top_options => toplist, :expanded => expanded, :no_display => no_display}
  end
  
  def getColorFeature(f, chosen_cats)
    color_counts = CatSpec.count_feat("color")
    display_colours = %w(red orange yellow green blue purple pink white silver brown black).zip(
       %w(l   l       l       d   d     d     l     l     l     d     d    ))
    display_colours.select!{|color,b| chosen_cats.include?(color) or !color_counts[color].nil?}
    # Logical change: made no_display look at display_colours, just in case some are selected but have counts of 0
    # was: if color_counts[color].nil? && !chosen_cats.include?(color)
    no_display = display_colours.empty?
    return {:display_colours => display_colours, :no_display => no_display}
  end
  
  def getBinaryFeature(f)
    dobj = Session.search.userdatabins.select{|udb| udb.name == f.name}.first
    unchecked = dobj.nil? || dobj.value == false
    available_count = BinSpec.count_feat(f.name)
    no_display = (available_count == 0 and unchecked)
    return {:available_count => available_count, :unchecked => unchecked, :no_display => no_display}
  end
  
  def getDisplayedRanges(f, chosen_conts)
    fname = Session.quebec && f.name == "saleprice" ? "pricePlusEHF" : f.name #Substitude EHF price for regular price
    ranges = Ranges.cache[fname.to_sym]
    chosen_conts.each{|c| ranges << c unless ranges.include?(c)}
    displayed_ranges = displayRanges(f.name, ranges)
    no_display = !displayed_ranges.inject(false){|res,e| res || e[:count]>0}
    return {:displayed_ranges => displayed_ranges, :no_display => no_display}
  end
  
  def getContinuousDistribution(f)
    distribution_data = getDist(f.name)
    no_display = distribution_data.blank?
    single_value = (no_display or distribution_data.first[2] != distribution_data.first[3]) ? nil : distribution_data.first[2]
    return {:distribution_data => distribution_data, :single_value => single_value, :no_display => no_display}
  end
  
  def getSliderSettings(f, distribution_data)
    current = Maybe(Session.search.userdataconts.select{|m|m.name == f.name}.first)
    step = calcInterval(distribution_data.first[2].floor,distribution_data.first[3].ceil)
    datamin = roundedInterval(distribution_data.first[2],step,true)
    datamax = roundedInterval(distribution_data.first[3],step,false)
    unit = @t["#{Session.product_type}.filter.#{f.name}.unit"] || ''
    return current, step, datamin, datamax, unit
  end
  
  def product_title
    if I18n.locale == :fr
      @t["#{Session.product_type}.name"]
    else
      val = @t["#{Session.product_type}.name"] || t("#{Session.product_type}.name")
      Session.search.products_size == 1 ? val : val.pluralize
    end
  end
  
  def number_results
    Session.search.products_size == 1 ? t("products.compare.product") : t("products.compare.product").pluralize
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
    displayRanges(name, Ranges.cache[name.to_sym]).select{|r| !values.select{|v| v.min == r[:min]}.empty? }
  end

  def spec_type(spec)
    ret = nil
    case 
    when spec.class == Userdatacont
      if Facet.find_by_name_and_product_type_and_used_for(spec.name, Session.product_type, 'filter').ui == "slider"
        ret = 'slider'
      else
        ret = 'continuous'
      end
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
    # getting the currently applied filters in order that they appear in the page
    # without extra processing, the values of the categorical filters are also in the same order as in the page
    filters = Session.search.userdataconts + Session.search.userdatacats + Session.search.userdatabins
    return [] if filters.empty? && Session.search.keyword_search.to_s.empty?
    
    # make the filter facets grouped by name into a list sorted by the order of each facet
    sorted = filters.group_by{|x|x.name}.sort_by  do |name, values|
      Facet.find_by_name_and_product_type_and_used_for(name, Session.product_type, 'filter').try(:value) || 0
    end
    
    # add ordering; another option would be to make page_order into a hash by name
    page_order = Session.features['filter'].map{ |f| {:name => f.name, :feature_type => f.feature_type, :value => f.value, :printed => false} }
    new_sorted = []
    sorted.each do |name, values|
      item = page_order.select{|f| f[:name] == name}[0]
      unless item.nil?
        new_group = {name => []}
        values.each do |v|
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
    end
    new_sorted.insert(0, ["Keyword", [Userdatacat.new(name: 'keyword', value: Session.search.keyword_search)]]) unless Session.search.keyword_search.to_s.empty?
    new_sorted
  end
  
  def displaySelectedString(spec, range)
    if spec.instance_of?(Userdatabin)
      @t["#{Session.product_type}.filter.#{spec.name}.name"] || spec.name
    elsif spec.instance_of?(Userdatacat)
      escaped_value = spec.value.gsub('.','-')
      if spec.name == "product_type"
        @t["#{escaped_value}.name"] || t("#{escaped_value}.name", :default => spec.value)
      else
        t(escaped_value, :scope => [:cat_option, Session.retailer, spec.name], :default => spec.value)
      end
    elsif spec.instance_of?(Userdatacont)
      unless range.nil?
        range[:display]
      else
        displayRanges(spec.name, [{:min => spec.min, :max => spec.max}], true)[0][:display]
      end
    end
  end
  
	def getDist(feat)
    num_buckets = 24
    discretized = Session.search.solr_search(mycats: Session.search.userdatacats, mybins: Session.search.userdatabins, myconts: Session.search.userdataconts).facet(feat.to_sym).rows
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
      unless discretized.select{|p| (min..max)===p.value }.empty?
        dataMin = discretized.select{|p| (min..max)===p.value }.first.value
        dataMax = discretized.select{|p| (min..max)===p.value }.last.value
      else
        dataMin = min
        dataMax = max
      end
      #Normalize to a max of 1
      maxval = dist.max
      dist.map!{|i| i.to_f / maxval}
      [[dataMin,dataMax]+[min_all,max_all],dist]
    else
      []
    end
  end
  def my_number_to_currency(num)
    if num.to_i == num 
      number_to_currency(num, :precision => 0)
    else
      number_to_currency(num, :precision => 2)  
    end  
  end  
  
  
  def my_to_i(num)
    if num.to_i == num 
      num.to_i
    else
      num
    end    
  end
  
  def tb(num)
    if num >=1000
      my_to_i(num.to_f/1000)
    else
      my_to_i(num)
    end    
  end  
  
  def displayRanges(feat, ranges, full=false)
    dr = []
    unless ranges.nil?
      unit = @t["#{Session.product_type}.filter.#{feat}.unit"]
      ranges.each_with_index do |r, ind|
        r[:min] = my_to_i(r[:min]) 
        r[:max] = my_to_i(r[:max])
        dr << {:count => Ranges.count(feat, r[:min], r[:max]), :min => r[:min], :max => r[:max], :display => ""}
        if r[:min] == r[:max]
          if feat == "saleprice"
            dis = my_number_to_currency(r[:min])
          elsif (feat=="capacity" && r[:min] >=1000) 
            dis = "#{number_with_delimiter(tb(r[:min]))} " + (I18n.locale == :en ? "TB" : "To")
          else
            dis =  "#{number_with_delimiter(r[:min])} " + unit
          end
        else
          if feat == "saleprice"
            dis = my_number_to_currency(r[:min]) + " - " + my_number_to_currency(r[:max])              
          elsif (feat=="capacity" && r[:min] >=1000) 
            dis = "#{number_with_delimiter(tb(r[:min]))} - #{number_with_delimiter(tb(r[:max]))} " + (I18n.locale == :en ? "TB" : "To")
          else
            dis = "#{number_with_delimiter(r[:min])} - #{number_with_delimiter(r[:max])} " + unit
          end    
        end 
        dr.last[:display] << dis
      end   
    end  
    unless dr.empty? or full == true
      unit = @t["#{Session.product_type}.filter.#{feat}.unit"] || t("#{Session.product_type}.filter.#{feat}.unit")
      if feat == "saleprice"
         dr.first[:display] = (dr.first[:max] > 0 ? t("features.belowbefore") : '') + my_number_to_currency(dr.first[:max])
         dr.last[:display] = my_number_to_currency(dr.last[:min]) + t("features.rangeabove")  
      else
        if (feat=="capacity")
          dr.first[:display] = (dr.first[:max] >= 1000 ? ("#{number_with_delimiter(tb(dr.first[:max]))} " + (I18n.locale == :en ? "TB" : "To")) : ("#{number_with_delimiter(dr.first[:max])} " + @t["#{Session.product_type}.filter.#{feat}.unit"])) + (dr.first[:max] > 0 ? t("features.rangebelow") : "") 
          dr.last[:display] = (dr.last[:min] >= 1000 ? ("#{number_with_delimiter(tb(dr.last[:min]))} "+ (I18n.locale == :en ? "TB" : "To")) : ("#{number_with_delimiter(dr.last[:min])} "+ @t["#{Session.product_type}.filter.#{feat}.unit"]) ) + t("features.rangeabove")
        else
          dr.first[:display] = "#{number_with_delimiter(dr.first[:max])} " + unit + (dr.first[:max] > 0 ? t("features.rangebelow") : "")
          dr.last[:display] = "#{number_with_delimiter(dr.last[:min])} "+ unit + t("features.rangeabove")
        end  
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
    (Session.features["sortby"] || []).map do |f|
        suffix = f.style.length > 0 ? '_' + f.style : ''
        content_tag :li, (current_sorting_option == (f.name+suffix)) ? @t[Session.product_type+".sortby."+f.name+suffix+".name"] : link_to(@t[Session.product_type+".sortby."+f.name+suffix+".name"], "#", {:'data-feat'=>f.name+suffix, :class=>"sortby"})
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
    ret += "&nbsp;" + numstars.to_s + " / 5" if Session.futureshop?
    return ret
  end
  
  def cat_order(f, chosen_cats, tree_level= 1)
    optionlist={}
    toplist = []
    if f.name == "product_type"
      optionlist = {}
      children = ProductCategory.get_subcategories(Session.product_type)
      leaves = CatSpec.count_feat(f.name)
      children.each do |fp|
        l = ProductCategory.get_leaves(fp)          
        optionlist[fp] = l.map{|e| leaves[e]}.compact.inject(0){|res,ele| res+ele}
      end
      if children.empty?
        leaf_type = Session.product_type
        optionlist[leaf_type] = leaves[leaf_type]
      end
    elsif f.name == "brand" # To ensure alphabetical sorting (regardless of capitalization)
      optionlist = CatSpec.count_feat(f.name)
      chosen_cats.each{|c| optionlist[c] = 0 unless optionlist.has_key?(c)}
      if optionlist.length > 10
        toplist = optionlist.keys[0..9]
      end
      optionlist = Hash[*optionlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
    else
      # Check if the feature has translations
      if I18n.t("cat_option.#{f.name}", :default => '').empty?
        optionlist = CatSpec.count_feat(f.name)
        chosen_cats.each{|c| optionlist[c] = 0 unless optionlist.has_key?(c)}
        if optionlist.length > 10
          toplist = optionlist.keys[0..9]
        end
        optionlist = Hash[*optionlist.sort{|a,b| a[0].downcase <=> b[0].downcase}.flatten]
      elsif f.name == "processorType" && Session.retailer == 'F'
        optionlist = CatSpec.count_feat(f.name)
        order = CatSpec.order(f.name)
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
          optionlist = Hash[*optionlist.to_a.sort{|a,b| order[a[0]] <=> order[b[0]] }.flatten]
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
    second_ancestors = CatSpec.count_feat("product_type",tree_level)
    subcategories = ProductCategory.get_subcategories(product_type).each do |sub|
      if second_ancestors.has_key?(sub) && second_ancestors[sub]>0
        optionlist[sub] = second_ancestors[sub]
      end
    end
    optionlist
  end
  
  def only_if_onsale(product)
    'style="display:none;"' unless BinSpec.cache_all(product.id)["onsale"]
  end
  
  def only_if_not_onsale(product)
    'style="display:none;"' if BinSpec.cache_all(product.id)["onsale"]
  end
  
  def dollars(p)
    number_with_precision(p.to_i, :precision => 0)
  end
  
  def cents(p)
    (number_with_precision(p - p.to_i, :precision => 2, :locale => :en).to_f * 100).to_i
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
    imageUrl = Session.retailer == 'A' ? TextSpec.find_by_product_id_and_name(product.id, 'image_url_m').try(:value) : product.image_url(size)
    # TODO: test without imageUrl.nil? - was for Amazon when missing image was not created
    if BinSpec.cache_all(product.id)["missingImage"] or imageUrl.nil?      #Load missing image placeholder
      content_tag(:div, "", :class => "imageholder", :'data-sku' => product.sku, :'data-id' => product.id)      
    else
      image_tag imageUrl, :class => size == :medium ? "productimg" : "", alt: "", :'data-id' => product.id, :'data-sku' => product.sku, :onerror => "javascript:this.onerror='';this.src='#{imageUrl}';return true;"
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
