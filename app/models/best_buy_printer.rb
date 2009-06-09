class BestBuyPrinter < ActiveRecord::Base
  named_scope :matched, :conditions => "printer_id IS NOT NULL"
  named_scope :unmatched, :conditions => "printer_id IS NULL"
end
