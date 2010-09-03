class AmazonCartridge < ActiveRecord::Base
  IDFeatures = %w(brand model asin)
  CategoricalFeatures = %w(brand model color compatible)
  ContinuousFeatures =  %w(yield)
  ScrapedFeatures = %w(brand model color compatible yield shelflife)
  scope :priced, :conditions => "price > 0"
  scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),CategoricalFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  scope :instock, :conditions => "instock is true"
  scope :instock_ca, :conditions => "instock_ca is true"
  scope :identifiable, :conditions => [IDFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  scope :scraped, :conditions => ScrapedFeatures.map{|i|i+' IS NOT NULL'}.join(' OR ')
  scope :matched, :conditions => 'product_id is not null'
  scope :toner, :conditions => 'toner is true'
end
