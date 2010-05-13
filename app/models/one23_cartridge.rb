class One23Cartridge < ActiveRecord::Base
  IDFeatures = %w(brand model)
  CategoricalFeatures = %w(brand model color)
  ContinuousFeatures =  %w(yield)
  named_scope :priced, :conditions => "price > 0"
  named_scope :toner, :conditions => "ink is false"
  named_scope :valid, :conditions => [ContinuousFeatures.map{|i|i+' > 0'}.join(' AND '),CategoricalFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
  named_scope :instock, :conditions => "instock is true"
  named_scope :instock_ca, :conditions => "instock_ca is true"
  named_scope :identifiable, :conditions => [IDFeatures.map{|i|i+' IS NOT NULL'}.join(' AND ')].delete_if{|l|l.blank?}.join(' AND ')
end
