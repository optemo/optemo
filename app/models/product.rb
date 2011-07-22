class Product < ActiveRecord::Base
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  has_many :search_products
  
  #define_index do
  #  #fields
  #  indexes "LOWER(title)", :as => :title
  #  indexes "product_type", :as => :product_type
  #  set_property :enable_star => true
  #  set_property :min_prefix_len => 2
  #  ThinkingSphinx.updates_enabled = false
  #  ThinkingSphinx.deltas_enabled = false
  #end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Product#{id}"){find(id)}
  end
  
  #Returns an array of results
  def self.manycached(ids)
    res = CachingMemcached.cache_lookup("ManyProducts#{ids.join(',').hash}"){find(ids)}
    if res.class == Array
      res
    else
      [res]
    end
  end
  
  def self.initial
    #Algorithm for calculating id of initial products in product_searches table
    #We probably need a better algorithm to check for collisions
    chars = []
    Session.product_type.each_char{|c|chars<<c.getbyte(0)*chars.size}
    chars.sum*-1
  end
  
  def self.filterspecs
    st = []
    Session.continuous["filter"].each do |f| 
      data = Session.search.products.mapfeat(f).compact
      raise ValidationError, "Can't find data for feature: #{f}" if data.empty?
      st << data
    end
    st
  end
  
  #This function is deprecated and would need to be updated if used
  def self.specs(p_ids = nil)
    st = []
    Session.continuous["cluster"].each{|f| st << ContSpec.by_feat(f)}
   # Session.binary["cluster"].each{|f| st<< self.to_bin_array(CatSpec.all(f))}
   #  Session.categorical["cluster"].each{|f| st<< self.to_cat_array(CatSpec.all(f))}  
    #Check for 1 spec per product
    raise ValidationError unless Session.search.products_size == st.first.length
    #Check for no nil values
    raise ValidationError unless st.first.size == st.first.compact.size
    raise ValidationError unless st.first.size > 0
    #Check that every spec has the same number of features
    first_size = st.first.compact.size
    st
  end
  
  
  
  scope :instock, :conditions => {:instock => true}
  scope :valid, lambda {
    {:conditions => (Session.continuous["filter"].map{|f|"id in (select product_id from cont_specs where #{Session.minimum[f] ? "value > " + Session.minimum[f].to_s : "value > 0"}#{" and value < " + Session.maximum[f].to_s if Session.maximum[f]} and name = '#{f}' and product_type = '#{Session.product_type}')"}+\
    Session.categorical["filter"].map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.product_type}')"}).join(" and ")}
  }
  scope :current_type, lambda {
    {:conditions => {:product_type => Session.product_type}}
  }
  #Session.binary["filter"].map{|f|"id in (select product_id from bin_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.product_type}')"}+\
    
  def brand
    @brand ||= cat_specs.cache_all(id)["brand"]
  end
  
  def tinyTitle
    @tinyTitle ||= [brand.gsub("Hewlett-Packard", "HP"),(model || cat_specs.cache_all(id)["model"] || cat_specs.cache_all(id)["mpn"]).split(' ')[0]].join(' ')
  end
  
  def descurl
    small_title.tr(' /','_-').tr('.', '-')
  end
  
  def small_title
    [brand.split(' ').map{|bn| bn=(bn==bn.upcase ? bn.capitalize : bn)}.join(' '), model || cat_specs.cache_all(id)["model"]].join(" ")
  end

  def navbox_display_title
    if small_title.length > 43
      small_title[0..43].gsub(/\s[^\s]*$/,'')
    else
      small_title
    end
  end

  def mobile_descurl
    "/show/"+[id,brand,model || cat_specs.cache_all(id)["model"] || cat_specs.cache_all(id)["mpn"]].join('-').tr(' /','_-')
  end
  
  def display(attr, data) # This function is probably superceded by resolutionmaxunit, etc., defined in the appropriate YAML file (e.g. printer_us.yml)
    if data.nil?
      return 'Unknown'
    elsif data == false
      return "None"
    elsif data == true
      return "Yes"
    else
      ending = case attr
        # The following lines are definitely superceded, as noted above
#        when /zoom/
#          ' X'
#        when /[^p][^a][^p][^e][^r]size/
#          ' in.' 
        when /(item|package)(weight)/
          data = data.to_f/100
          ' lbs'
        when /focal/
          ' mm.'
        when /ttp/
          ' seconds'
        else ''
      end
    end
    data.to_s+ending
  end
  
  def self.per_page
    9
  end
  def self.to_bin_array(a)
    a.map{|i| i==1 ? [1,0] : [0,1]}
  end  
  def self.to_cat_array(a) # converting categorical values to numbers
    uniqVals = a.uniq
    r = uniqVals.size
    a.map{|i| s=[0]*r; s[uniqVals.index(i)]=1;s}
  end  
end
class ValidationError < ArgumentError; end
