class DbProperty < ActiveRecord::Base
  def toPhrase(prop,v,optional="")
    case prop
      when "maximumresolution": res = ['high resolution','low resolution']
      when "displaysize": res = ['large display','small display']
      when "opticalzoom": res = ['large zoom','small zoom']
      else return nil
    end
    if !v.nil? && v >= db_features.find_by_name(prop).high
      '<span class="high">'+res[0]+'</span>'+optional
    elsif !v.nil? && v <= db_features.find_by_name(prop).low
      '<span class="low">'+res[1]+'</span>'+optional
    else
      ""
    end
  end
end
