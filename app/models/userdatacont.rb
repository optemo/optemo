class Userdatacont < ActiveRecord::Base
  def range
    FloatRange.new(min,max,name)
  end
  
  def to_s
    range.to_s
  end
  
  def data_id
    if Session.features["filter"].find{|f|f.name == name}.try(:ui) == "ranges"
      "Userdatacont#{id}"
    else
      "slider#{name}"
    end
  end
end
