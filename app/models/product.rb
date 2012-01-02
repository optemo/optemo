require "sunspot"
require 'sunspot_autocomplete'
require "autocomplete_view_helpers"

class Product < ActiveRecord::Base
  has_many :cat_specs
  has_many :bin_specs
  has_many :cont_specs
  has_many :text_specs
  has_many :search_products
  has_one :product_bundle, :foreign_key=>:bundle_id
  has_many :product_siblings
  has_many :product_bundles

  #define_index do
  #  #fields
  #  indexes "LOWER(title)", :as => :title
  #  indexes "product_type", :as => :product_type
  #  set_property :enable_star => true
  #  set_property :min_prefix_len => 2
  #  ThinkingSphinx.updates_enabled = false
  #  ThinkingSphinx.deltas_enabled = false
  #end
  attr_writer :product_name
  searchable do
    #text :title do
    text :title do
      cat_specs.find_by_name("title").try(:value)
    end
     
    text :description do
      text_specs.find_by_name("longDescription").try(:value)
    end
    
    text :sku 
    boolean :instock
    autosuggest :product_name, :using => :title
    autocomplete :post_title, :using => :title
    puts "test2: #{:product_name}"
    #autocomplete :post_description, :using => :description 
  end
  
  def self.cached(id)
    CachingMemcached.cache_lookup("Product#{id}"){find(id)}
  end
  
  def self.by_sku(sku)
    CachingMemcached.cache_lookup("Product-sku#{sku}"){find_by_sku(sku)}
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
end
class ValidationError < ArgumentError; end
