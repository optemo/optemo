class DbProperty < ActiveRecord::Base
  has_many :db_features
  def toPhrase(prop,v,optional="")
    case prop
      when "maximumresolution": res = ['high resolution','low resolution']
      when "displaysize": res = ['large display','small display']
      when "opticalzoom": res = ['large zoom','small zoom']
      else return nil
    end
    if v >= db_features.find_by_name(prop).high
      '<span class="high">'+res[0]+'</span>'+optional
    elsif v <= db_features.find_by_name(prop).low
      '<span class="low">'+res[1]+'</span>'+optional
    else
      ""
    end
  end
end
