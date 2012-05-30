module DirectComparisonHelper
  def feature_value(product_id, spec, gray, feature, column_number)
    feat = feature.name
    content_tag :div, :class => ["cell", gray ? "graybg" : "whitebg", "spec_column_"+column_number.to_s], :style => Maybe(@bestvalue[feature.name]).include?(product_id) ? "font-weight:bold;" : "" do
      if feature.feature_type == "Continuous"
    	  if spec.nil?
    		  "-"
    	  elsif feature.name=="saleprice"
    	  	number_to_currency(spec)
    	  else
    	  	number_with_delimiter(spec).to_s + " " + t("#{Session.product_type}.specs.#{feature.name}.unit", :default => "")
    	  end
      elsif feature.feature_type == "Categorical"
        trans_key = (feature.name == "product_type") ? "#{spec}.name" : "cat_option.#{Session.retailer}.#{feature.name}.#{spec.downcase.strip.gsub('.','-')}" unless spec.nil?
        t(trans_key, :default => spec.nil? ? "-" : spec.to_s)
      else #Binary -- might need to add another elsif clause for text specs later
      	spec ? t('compare.index.yesoption') : t('compare.index.nooption')
      end
    end
  end
  def box_width
    [(@products.size - 2) * 201,0].max + 531
  end
end