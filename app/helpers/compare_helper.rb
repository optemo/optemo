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

  def product_title
    if I18n.locale == :fr
      t("#{Session.product_type}.name")
    else
      val = t("#{Session.product_type}.name")
      Session.search.products_size == 1 ? val : val.pluralize
    end
  end
  
  def number_results
    Session.search.products_size == 1 ? t("products.compare.product") : t("products.compare.product").pluralize
  end

  def showSelectedRanges(values, name)
    displayRanges(name, Ranges.cache[name.to_sym]).select{|r| !values.select{|v| v.min == r[:min]}.empty? }
  end
  
  def my_to_i(num)
    if num.to_i == num 
      num.to_i
    else
      num
    end    
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
    current_sorting_option = Session.search.sortby || (Session.features["sortby"].first.name + '_' + Session.features['sortby'].first.style)
    (Session.features["sortby"] || []).map do |f|
        fname = (f.name == 'pricePlusEHF' ? "saleprice" : f.name)
        suffix = f.style.length > 0 ? '_' + f.style : ''
        content_tag :li, (current_sorting_option == (f.name+suffix)) ? t(f.product_type+".sortby."+fname+suffix+".name") : link_to(t(f.product_type+".sortby."+fname+suffix+".name"), "#", {:'data-feat'=>f.name+suffix, :class=>"sortby"})
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
    ret += "&nbsp;" + numstars.to_s if Session.futureshop?
    return ret
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
  
  def product_type_link(type,name)
    if (type == Session.product_type)
      content_tag("b", name)
    else
      link_to name, "?category_id=#{type}" 
    end
  end
  
  def product_image(product,size)
    imageUrl = Session.amazon? ? TextSpec.find_by_product_id_and_name(product.id, 'image_url_m').try(:value) : product.image_url(size)
    # TODO: test without imageUrl.nil? - was for Amazon when missing image was not created
    if BinSpec.cache_all(product.id)["missingImage"] or imageUrl.nil?      #Load missing image placeholder
      content_tag(:div, "", :class => "imageholder", :'data-sku' => product.sku, :'data-id' => product.id)      
    else
      image_tag imageUrl, :class => size == :medium ? "productimg" : "productimg_s", alt: "", :'data-id' => product.id, :'data-sku' => product.sku, :onerror => "javascript:this.onerror='';this.src='#{imageUrl}';return true;"
    end
  end
  
  def your_selections
    res = "".html_safe
    last_heading = nil
    if Session.search.keyword_search and not Session.search.keyword_search.empty?
      keyword_facet = Categorical.new(name: "keyword")
      keyword_value = Userdatacat.new(name: "keyword", value: Session.search.keyword_search)
      last_heading = render(partial: 'filter_label', object: keyword_facet, locals: {selected: true}) 
      result = render partial: "selected", collection: [keyword_value], locals: {last_heading: last_heading}
      res += result unless result.nil?
    end
    Session.features["filter"].each do |f|
      last_heading = render(partial: 'filter_label', object: f, locals: {selected: true}) unless f.is_a? Binary
      unless f.is_a? Heading
        result = render partial: "selected", collection: f.selected, locals: {last_heading: last_heading}
        res += result unless result.nil?
      end
    end
    unless res.blank? #Don't you your_selections if they're empty
      render layout: 'your_selections' do
        res
      end
    end
  end
end

module WillPaginate
  module ViewHelpers
    def page_entries_info(collection, options = {})
      entry_name = options[:entry_name] ||
        (collection.empty? ? 'entry' :
          collection.first.class.name.underscore.sub('_', ' '))
      t('will_paginate.page_entries_info.multi_page_html', :from => collection.offset + 1, :to => collection.offset + collection.length, :count => collection.total_entries)
    end
  end
end
