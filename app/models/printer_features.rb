class PrinterFeatures < ActiveRecord::Base

  def commit(sessionId)
    oldfeatures = PrinterFeatures.find(:first, :conditions => ['session_id = ?', sessionId])
    atts = attributes
    # Remove all nil fields from atts except if their BinaryFeatures as we're tracking only positive check boxes
    atts.delete_if{|k,v|v.blank? && !k.index(/#{$model::BinaryFeatures.join('|')}/)}
    oldfeatures.update_attributes(atts)    
  end
  
end
