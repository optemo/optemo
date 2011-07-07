class ProductType < ActiveRecord::Base
  has_many :urls
  has_many :headings
  has_many :features, :through => :headings
  has_many :category_id_product_type_maps

  validates_presence_of :name
end
