class DbProperty < ActiveRecord::Base
  has_many :db_features
  def toPhrase(prop,v,optional="")
    case prop
      when "maximumresolution": res = ['high resolution','low resolution']
      when "displaysize": res = ['large display','small display']
      when "opticalzoom": res = ['large zoom','small zoom']
      else return nil
    end
    high = prop+"_high"
    low = prop+"_low"
    if v >= send(high.intern)
      '<span class="high">'+res[0]+'</span>'+optional
    elsif v <= send(low.intern)
      '<span class="low">'+res[1]+'</span>'+optional
    else
      ""
    end
  end
end
