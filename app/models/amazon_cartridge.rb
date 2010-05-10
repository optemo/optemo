class AmazonCartridge < ActiveRecord::Base
  IDFeatures = %w(brand model asin)
  CategoricalFeatures = %w(brand model color compatible)
  ContinuousFeatures =  %w(yield)
  ScrapedFeatures = %w(brand model color compatible yield shelflife)
  named_scope :priced, :conditions => "price > 0"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),CategoricalFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  named_scope :identifiable, :conditions => [IDFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :scraped, :conditions => ScrapedFeatures.map{|i|i+' IS NOT NULL'}.join(' OR ')
  named_scope :matched, :conditions => 'product_id is not null'
  named_scope :toner, :conditions => 'toner is true'
end
