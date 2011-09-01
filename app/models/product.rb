class Product < ActiveRecord::Base
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  has_many :text_specs
  has_many :search_products
  has_one :product_bundle, :foreign_key=>:bundle_id
  self.per_page = 18

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
  
  scope :instock, :conditions => {:instock => true}
  scope :valid, lambda {
    {:conditions => (Session.current.features["filter"].select{|f|f.feature_type == "continuous"}).map{|f|"id in (select product_id from cont_specs where #{Session.minimum[f] ? "value > " + Session.minimum[f].to_s : "value > 0"}#{" and value < " + Session.maximum[f].to_s if Session.maximum[f]} and name = '#{f}' and product_type = '#{Session.product_type}')"}+\
    Session.current.features["filter"].select{|f|f.feature_type == "categorical"}.map{|f|"id in (select product_id from cat_specs where value IS NOT NULL and name = '#{f}' and product_type = '#{Session.product_type}')"}).join(" and ")}
  }
  scope :current_type, lambda {
    {:conditions => {:product_type => Session.product_type}}
  }
    
  def brand
    if I18n.locale == :fr
      cat_specs.cache_all(id)["brand_fr"]
    else
      @brand ||= cat_specs.cache_all(id)["brand"]
    end
  end
  
  def tinyTitle
    @tinyTitle ||= [brand.gsub("Hewlett-Packard", "HP"),(cat_specs.cache_all(id)["model"] || model || cat_specs.cache_all(id)["mpn"]).split(' ')[0]].join(' ')
  end
  
  def mobile_descurl
    "/show/"+[id,brand,cat_specs.cache_all(id)["model"] || model || cat_specs.cache_all(id)["mpn"]].join('-').tr(' /','_-')
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
