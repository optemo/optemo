class Facet < ActiveRecord::Base
  has_many :dynamic_facets, :dependent=>:delete_all
  self.inheritance_column = 'feature_type'
 
  after_save{ Maybe(dynamic_facets).each{|x| x.save}}
end
