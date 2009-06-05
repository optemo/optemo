require 'ecs'
desc "Download BestBuy data with Remix"
task :remix_BestBuy => :environment do
  e = BestBuy::Ecs.new
  r = e.product_search({:category => 'Laser'})
  puts r.total_results
  puts r.items.first.get_hash.keys
  puts r.items.first.get_hash[:sku]
end