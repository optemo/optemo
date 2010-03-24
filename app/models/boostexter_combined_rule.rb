class BoostexterCombinedRule < ActiveRecord::Base
  set_table_name "#{$model.table_name().chop()}_boostexter_combined_rules"
end
