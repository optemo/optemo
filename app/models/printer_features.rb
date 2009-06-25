class PrinterFeatures < ActiveRecord::Base

  def commit(sessionId)
    oldfeatures = PrinterFeatures.find(:first, :conditions => ['session_id = ?', sessionId])
    atts = attributes
    # Remove all nil fields from atts
    atts.delete_if{|k,v|v.blank?}    
    oldfeatures.update_attributes(atts)    
  end
  
end
