class PrinterFeatures < ActiveRecord::Base

  def commit
    @oldfeatures = PrinterFeatures.find(:first, :conditions => ['session_id = ?', session_id]) unless @oldfeatures
    @oldfeatures.update_attributes(attributes)
    
  end
  
end
