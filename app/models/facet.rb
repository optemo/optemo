class Facet < ActiveRecord::Base
  has_many :dynamic_facets, :dependent=>:delete_all
  after_save{ Maybe(dynamic_facets).each{|x| x.save}}
    


  def self.transfer_data_from_feature
    Facet.destroy_all
    Feature.all.each do |f|
      if f.used_for.blank?
        fa = Facet.new(:name=>f.name, :product_type_id=>f.heading.product_type_id, :feature_type=>f.feature_type, :value=>f.used_for_order*(f.larger_is_better ? 1: -1))
        fa.save
      else
        Maybe(f.used_for.split(',').reject{|x| x.blank?}).map{|x| x.strip}.each do |u|
          if u != 'cluster' && u != 'utility'
            
            fa = Facet.new(:name=>f.name, :product_type_id=>f.heading.product_type_id, :feature_type=>f.feature_type, :used_for=>u, :value=>f.used_for_order*(f.larger_is_better ? 1: -1))
            if u == 'filter'
              Maybe(f.used_for_categories).split(',').reject{|x| x.blank?}.map{|x| x.strip}.each do |uc|
                fa.dynamic_facets << DynamicFacet.new(:category=>uc.strip)
              end
            end
          else

          end
          if f.cluster_weight > 1
            Facet.create(:name=>f.name, :product_type_id=>f.heading.product_type_id, :feature_type=>f.feature_type, :value=>f.cluster_weight*(f.larger_is_better ? 1: -1), :used_for=>'cluster')
          end
          if f.utility_weight > 1
            Facet.create(:name=>f.name, :product_type_id=>f.heading.product_type_id, :feature_type=>f.feature_type, :value=>f.utility_weight*(f.larger_is_better ? 1: -1), :used_for=>'utility')
          end

          fa.save          
        end
      end
    end
    [2, 6].each{ |id| Facet.create(:name=>'status', :product_type_id=>id, :feature_type=>'Binary', :used_for=>'heading', :value=>2)}
    
  end
end
