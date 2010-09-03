class One23Cartridge < ActiveRecord::Base
  IDFeatures = %w(brand model)
  CategoricalFeatures = %w(brand model color)
  ContinuousFeatures =  %w(yield)
  scope :priced, :conditions => "price > 0"
  scope :toner, :conditions => "ink is false"
  scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),CategoricalFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  scope :instock, :conditions => "instock is true"
  scope :instock_ca, :conditions => "instock_ca is true"
  scope :identifiable, :conditions => [IDFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
end
