class DbFeature < ActiveRecord::Base
  def self.cache
    unless defined? @@dbf
      @@dbf = {}
      find_all_by_product_type_and_region($model.name,$region).each {|f| @@dbf[f.name] = f}
    end
    @@dbf
  end
end
