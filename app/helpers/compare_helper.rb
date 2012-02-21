module CompareHelper
  def main_boxes
    res = []
    @s.search.paginated_products.map{|p|Product.cached(p.id)}.each_slice(3) do |box1,box2,box3|
      res << content_tag("div") do
        render(:partial => 'navbox', :locals => {product: box1, last_in_row: false}) +
        render(:partial => 'navbox', :locals => {product: box2, last_in_row: false}) +
        render(:partial => 'navbox', :locals => {product: box3, last_in_row: true})
      end
    end
    res.join(tag("div", :style => "height:1px;width: 520px;border-top:1px #ccc solid;margin: 0 auto 8px;", class: "divider"))
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

	def getDist(feat)
    num_buckets = 24
    discretized = Session.search.solr_cached.facet(feat.to_sym).rows
    if (!discretized.empty?)
      min_all = CachingMemcached.cache_lookup("Min#{Session.search.keyword_search}#{feat}") {discretized.first.value}
      max_all = CachingMemcached.cache_lookup("Max#{Session.search.keyword_search}#{feat}") {discretized.last.value}
   
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
    current_sorting_option = Session.search.sortby || "utility"
    Session.features["sortby"].map do |f| 
      suffix = f.style.length > 0 ? '_' + f.style : ''
      content_tag :li, (current_sorting_option == (f.name+suffix)) ? t("specs."+f.name+suffix) : link_to(t("specs."+f.name+suffix), "#", {:'data-feat'=>f.name+suffix, :class=>"sortby"})
    end.join(content_tag(:span, "  |  ", :class => "seperater"))
  end
  
  def stars(numstars)
    fullstars = numstars.to_i
    halfstar = (fullstars == numstars) ? 0 : 1
    emptystars = 5 - fullstars - halfstar
    ret = ""
    fullstars.times do
      ret += '<img src="http://bestbuy.ca/images/common/pictures/yellowStar.gif" /> '
    end
    halfstar.times do
      ret += '<img src="http://bestbuy.ca/images/common/pictures/yellowhalfstar.gif" /> '
    end
    emptystars.times do
      ret += '<img src="http://bestbuy.ca/images/common/pictures/emptystar.gif" /> '
    end
    return ret
  end
  
  def cat_order(f, chosen_cats, tree_level= 1)
   optionlist={}
    if (request.host =="keyword")       
       if f.name == "category"
       #IMPLEMENTATION WITHOUT INDEXING THE FIRST AND SECOND ANCESTORS
       #  leaves = CatSpec.count_feat(f.name)
       # # puts "leaves_compare #{leaves}"
       #  Session.product_type_ancestors(leaves.keys, tree_level).each do |fp|
       #    l = Session.product_type_leaves(fp)
       #   # puts "first_ancestor #{fp} its leaves #{l}"
       #    optionlist[fp] = l.map{|e| leaves[e]}.compact.inject{|res,ele| res+ ele}
       #  end
       #***************
         optionlist = CatSpec.count_feat(f.name, tree_level)
       else
        optionlist = CatSpec.count_feat(f.name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
       end
    else 
      optionlist = CatSpec.count_feat(f.name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
  	  order = CatSpec.order(f.name)
      unless order.empty?
        optionlist = optionlist.to_a.sort{|a,b| (chosen_cats.include?(a[0]) ? a[1]-1000000 : order[a[0]]) <=> (chosen_cats.include?(b[0]) ? b[1]-1000000 : order[b[0]])} 
      end
    end
  	optionlist
  end
 
  def sub_level(product_type, tree_level= 2)
    optionlist={}
   #IMPLEMENTATION WITHOUT INDEXING THE FIRST AND SECOND ANCESTORS
   # leaves = CatSpec.count_feat("category")
   # ancestors = Session.product_type_ancestors(leaves.keys, tree_level)
   # subcategories = Session.product_type_subcategory(product_type).each do |sub|
   #    if ancestors.include?(sub)
   #     optionlist[sub] =  Session.product_type_leaves(sub).map{|e| leaves[e]}.compact.inject{|res,ele| res+ ele}
   #    end
   # end
   #puts "sub_level #{ancestors} #{subcategories}"
   #****************
    second_ancestors = CatSpec.count_feat("category",tree_level)
    subcategories = Session.product_type_subcategory(product_type).each do |sub|
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
end
