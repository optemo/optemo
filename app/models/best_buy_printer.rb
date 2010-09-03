class BestBuyPrinter < ActiveRecord::Base
  scope :matched, :conditions => "printer_id IS NOT NULL"
  scope :unmatched, :conditions => "printer_id IS NULL"
end
