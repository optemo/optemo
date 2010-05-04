class BoostexterRule < ActiveRecord::Base
  # This is a good idea, but right now the boostexter_combined_rules only works for cameras (March 23). Update this in future.
  def self.bycluster(cluster_id)
    CachingMemcached.cache_lookup("BoostexterRules#{cluster_id}") do
      PrinterBoostexterCombinedRule.find(:all, :order => "weight DESC", :conditions => {"cluster_id" => cluster_id})
    end
  end
end
