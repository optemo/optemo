class Printer < ActiveRecord::Base
  named_scope :valid, :conditions => "salepriceint IS NOT NULL"
end
