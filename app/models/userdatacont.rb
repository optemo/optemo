class Userdatacont < ActiveRecord::Base
  def range
    FloatRange.new(min,max,name)
  end
  
  def to_s
    range.to_s
  end
  
  def data_id
    if Session.features["filter"].find{|f|f.name == name}.try(:ui) == "slider"
      "slider#{name}"
    else
      "Userdatacont#{id}"
    end
  end
  
  def bwname
    #for backward compatibility
    "continuous_#{name}"
  end
  
  def value
    #for backwards compatibility
    "#{min};#{max}"
  end
end
