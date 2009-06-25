class PrinterFeatures < ActiveRecord::Base

  def commit(sessionId)
    oldfeatures = PrinterFeatures.find(:first, :conditions => ['session_id = ?', sessionId])
    oldfeatures.update_attributes(attributes)
  end
  
end
