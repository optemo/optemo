class ProductType < ActiveRecord::Base
  has_many :product_type_urls
  has_many :product_type_headings
  has_many :product_type_features, :through => :product_type_headings
end
