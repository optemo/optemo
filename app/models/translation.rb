class Translation < ActiveRecord::Base
  # These next somewhat messy lines are an optimization aimed at pre-loading all of the translations.
  # This saves on individual Activerecord requests / instantiations later.

  def self.cache_brands(brand_array) # Returns specs for every product in the list
    if brand_array.blank?
      {}
    else
      CachingMemcached.cache_lookup("TranslationGroup#{I18n.locale}#{brand_array.join(',')}") do
        brand_hash = {}
        I18n::Backend::ActiveRecord::Translation.find_by_sql("SELECT `key`,`value` FROM `translations` WHERE `locale` = '#{I18n.locale}' AND `key` LIKE "+ brand_array.map{|x|"'%B.brand."+x+"%'"}.join(" OR `key` LIKE ")).each{|b| brand_hash[b.key] = b["value"]}
        brand_hash
      end
    end
  end
  
  def self.cache_product_translations
    # This function is probably far too specific but it is fast
    # cache translations that are under the current product type, its children, and the leaves under it
    CachingMemcached.cache_lookup("TranslationProductType#{I18n.locale}#{Session.product_type}") do
      I18n::Backend::ActiveRecord::Translation.find_by_sql("SELECT `key`,`value` FROM `translations` WHERE `locale` = '#{I18n.locale}' AND (`key` LIKE '#{Session.product_type}%'" + (ProductCategory.get_subcategories(Session.product_type) + [Session.landing_page]).map{|x| " OR `key` LIKE '" + x + "%'"}.join("")+")").inject({}) do |h,f|
        h[f["key"]] = f["value"]
        h
      end
    end
  end
end
