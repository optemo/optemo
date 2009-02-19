class Printer < ActiveRecord::Base
  named_scope :priced, :conditions => "salepriceint IS NOT NULL"
  named_scope :valid, :conditions => %w(salepriceint ppm ttp paperoutput paperinput).map{|i|i+' IS NOT NULL'}.join(' AND ')
  MainFeatures = %w(ppm ttp resolution salepriceint)
end
