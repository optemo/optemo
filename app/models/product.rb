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
  has_one :equivalence
  
  searchable do
    text :title do
      text_specs.find_by_name("title").try(:value)
    end

    text :description do
      text_specs.find_by_name("longDescription").try(:value)
    end
    text :sku
    boolean :instock
    string :eq_id_str
    integer :isBundleCont do
      cont_specs.find_by_name(:isBundleCont).try(:value)
    end
    string :product_type do
      cat_specs.find_by_name(:product_type).try(:value)
    end
    string :product_category do
      cat_specs.find_by_name(:product_type).try(:value)
    end
    #text :category_of_product, :using => :get_category

    string :first_ancestors
    string :second_ancestors

   (Facet.find_all_by_used_for("filter")+Facet.find_all_by_used_for("sortby")).each do |s|
    if (s.feature_type == "Continuous")
      float s.name.to_sym, trie: true do
        cont_specs.find_by_name(s.name).try(:value)
      end
    elsif (s.feature_type == "Categorical")
      string s.name.to_sym do
        cat_specs.find_by_name(s.name).try(:value)
      end
    elsif (s.feature_type == "Binary")
      string s.name.to_sym do
        bin_specs.find_by_name(s.name).try(:value)
      end
    end
   end
    float :lr_utility, trie: true do
      cont_specs.find_by_name(:lr_utility).try(:value)
    end
    autosuggest :all_searchable_data, :using => :get_title
    #autosuggest :all_searchable_data, :using => :get_category # TODO: remove this
    #autosuggest :product_instock_title, :using => :instock?
  end
  
  def get_title
    title = text_specs.find_by_name("title").try(:value)
    if title.nil?
      false
    else
      title
    end
  end
  
  def first_ancestors
    if pt = cat_specs.find_by_name(:product_type)
      list = ProductCategory.get_ancestors(pt.value, 3)
      list.join("")+"#{pt.value}" if list
    end
  end
  
  def second_ancestors
    if pt = cat_specs.find_by_name(:product_type)
      list = ProductCategory.get_ancestors(pt.value, 4)
      list.join("")+"#{pt.value}" if list
    end
  end
  
  def eq_id_str
    Equivalence.find_by_product_id(id).try(:eq_id).to_s
  end

  def instock?
    if (instock)
      text_specs.find_by_name("title").try(:value)
    else
      false
    end
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
  scope :current_type, lambda{ joins(:cat_specs).where(cat_specs: {name: "product_type", value: Session.product_type_leaves})}
  
  
  def image_url(imgSize, pid=nil) #creates the url to a product's image given and sku and image size (thumbnail, small, medium, large -> predetermined sizes)
    if Session.retailer == "B"
      baseUrl = "http://www.bestbuy.ca/multimedia/Products/"
    elsif Session.retailer == "F"
      baseUrl = "http://www.futureshop.ca/multimedia/Products/"
    elsif Session.retailer == "A"
      url = TextSpec.find_by_product_id_and_name(pid, 'image_url_m')
      if url.nil?
        return nil
      else
        return url.value
      end
    end
    skuUrl = sku[0..2]+"/"+sku[0..4]+"/"+sku[0..7]+".jpg"
    case imgSize
    when :thumbnail
      sizeUrl = "55x55/"
    when :small
      sizeUrl = "100x100/"
    when :medium
      sizeUrl = "150x150/"
    when :large
      sizeUrl = "250x250/"
    
    end
    return baseUrl+sizeUrl+skuUrl
  end
end
class ValidationError < ArgumentError; end
