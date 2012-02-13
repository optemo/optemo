module CompareHelper

  def product_title
    if I18n.locale == :fr
      t("products.compare.title")
    else
      Session.search.products_size > 1 ? t("products.compare.title").pluralize : t("products.compare.title")
    end
  end
 
  def chosencats(feat)
    Session.search.userdatacats.select{|d|d.name == feat}.map{|x|x.value}
  end
  
  def main_boxes(landing = false)
    res = ""
    res << '<div class="rowdiv">'
    prods = landing ? @s.search.products_landing[1..-1] : @s.search.paginated_products #The first products_landing is the hero product
    # now the new mockup is only with featured products
    if landing
      res << "<div class='title_landing_type'>" + I18n.t("products.featuredproducts") + "</div>"
      res << "<div style='clear:both;width: 0;height: 0;'><!-- --></div>"
    end
    products = prods.map{|p|Product.cached(landing ? p : p.id)}
    loop do
      row = products.shift(3)
      #Check if any of the products have variations or bundles
      #no_variations = row.inject(true){|ans,p| ans && p.product_bundles.empty?}
      no_variations = row.inject(true){|ans,p| ans && p.product_siblings.empty?}
      row.each_index do |i|
        res << render(:partial => 'navbox', :locals => {product: row[i], landing: landing, last_in_row: i == row.length-1, no_variations: no_variations, bundles: row[i].product_bundles, siblings: row[i].product_siblings})
      end
      if products.empty?
        break
      else
        res << '<div style="clear:both;height:1px;width: 520px;border-top:1px #ccc solid;margin: 0 auto;"><!-- --></div>'
      end
    end
    res << '<div style="clear:both;height:0;"><!-- --></div></div>'
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
  
  def cat_order(f, chosen_cats)
    optionlist = CatSpec.count_feat(f.name).to_a.sort{|a,b| (chosen_cats.include?(b[0]) ? b[1]+1000000 : b[1]) <=> (chosen_cats.include?(a[0]) ? a[1]+1000000 : a[1])}
    unless (request.host =="keyword")
  	  order = CatSpec.order(f.name)
      unless order.empty?
        optionlist = optionlist.to_a.sort{|a,b| (chosen_cats.include?(a[0]) ? a[1]-1000000 : order[a[0]]) <=> (chosen_cats.include?(b[0]) ? b[1]-1000000 : order[b[0]])} 
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
