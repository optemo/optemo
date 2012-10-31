class Userdatacat < ActiveRecord::Base
  def to_s
    trans_key = (name == "product_type") ? "#{Session.landing_page}.filter.#{value}.name" : "cat_option.#{Session.retailer}.#{name}.#{value.gsub('.','-')}"
    I18n.t(trans_key, :default => ["#{value}.name".to_sym, value])
  end
  
  def data_id
    if name == "color"
      "swatchcolor"
    else
      "Userdatacat#{id}"
    end
  end
end
