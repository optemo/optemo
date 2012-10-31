class Userdatabin < ActiveRecord::Base
  def to_s
    I18n.t("#{Session.product_type}.filter.#{name}.name") || name.capitalize
  end
  
  def data_id
    "Userdatabin#{id}"
  end
end
