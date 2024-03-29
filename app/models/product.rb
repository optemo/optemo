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

  self.per_page = 18 #for will_paginate
  
  # Configure indexing and search for Product objects.
  # We define a separate function rather than directly calling the searchable DSL method, 
  # as this allows the setup to be run again after the Facet fixtures are loaded in the tests.
  def self.setup_sunspot
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
      text :category_of_product do # needed for keyword search to match category
        category = cat_specs.find_by_name(:product_type).try(:value)
        unless category.nil?  
          I18n.t "#{category}.name"
        end
      end    
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
      float :pricePlusEHF, trie: true do
        cont_specs.find_by_name(:pricePlusEHF).try(:value)
      end
      
      float :lr_utility, trie: true do
        cont_specs.find_by_name(:lr_utility).try(:value)
      end
      autosuggest :all_searchable_data do
        if (instock)
          text_specs.find_by_name("title").try(:value)
        end
      end
    end
  end
  
  # Setup Sunspot on initial load of this file.
  self.setup_sunspot
    
  def first_ancestors
    if pt = cat_specs.find_by_name(:product_type)
      cur_level = ProductCategory.find_by_product_type(pt.value).level
      list = ProductCategory.get_ancestors(pt.value, cur_level-1)
      list.join("") if list
    end
  end
  
  def second_ancestors
    if pt = cat_specs.find_by_name(:product_type)
      cur_level = ProductCategory.find_by_product_type(pt.value).level
      list = ProductCategory.get_ancestors(pt.value, cur_level-2)
      list.join("") if list
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
    CachingMemcached.cache_lookup("Product#{id}"){find_by_id(id)}
  end
  
  def self.by_sku(sku)
    CachingMemcached.cache_lookup("Product-sku#{sku}"){find_by_sku(sku)}
  end
  
  #Returns an array of results
  def self.cachemany(ids)
    res = CachingMemcached.cache_lookup("ManyProducts#{ids.join(',')}"){ids.map{|id|find_by_id(id)}.compact}
    if res.class == Array
      res
    else
      [res]
    end
  end

  def siblings_cached
    CachingMemcached.cache_lookup("Product#{id}Siblings"){product_siblings}
  end
  
  def bundles_cached
    CachingMemcached.cache_lookup("Product#{id}Bundles"){product_bundles}    
  end

  scope :instock, :conditions => {:instock => true}
  scope :current_type, lambda{ joins(:cat_specs).where(cat_specs: {name: "product_type", value: Session.product_type_leaves})}
  
  def image_url(imgSize) #creates the url to a product's image given and sku and image size (thumbnail, small, medium, large -> predetermined sizes)
    if Session.retailer == "B"
      baseUrl = "http://www.bestbuy.ca/multimedia/Products/"
    elsif Session.retailer == "F"
      baseUrl = "http://www.futureshop.ca/multimedia/Products/"
    else
      raise 'Invalid call to image_url with other retailer'
    end
    case imgSize
    when :thumbnail
      sizeUrl = "55x55"
      name = 'thumbnail_url'
    when :small
      sizeUrl = "100x100"
      name = 'image_url_s'
    when :medium
      sizeUrl = "150x150"
      name = 'image_url_m'
    when :large
      sizeUrl = "250x250"
      name = 'image_url_l'
    end
    url_spec = TextSpec.cache_all(id)[name]
    if url_spec.nil?
      if Session.futureshop?
        url = "http://www.futureshop.ca/multimedia/Products/#{sizeUrl}/"
      elsif Session.bestbuy?
        url = "http://www.bestbuy.ca/multimedia/Products/#{sizeUrl}/"
      else
        raise "No known image link for product: #{sku}"
      end
      url += sku[0..2].to_s+"/"+sku[0..4].to_s+"/"+sku.to_s+".jpg"
    else
      url_spec#.value
    end
  end
end
class ValidationError < ArgumentError; end
