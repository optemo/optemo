require 'ecs'
desc "Download BestBuy data with Remix"
task :remix_BestBuy => :environment do
  e = BestBuy::Ecs.new
  r = e.product_search({:category => 'Laser*'})
  puts "Total resuts: "+r.total_results.to_s
  downloadResults(r)
end

def downloadResults(r)
  loop do
    r.items.each do |i|
      h = i.get_hash
      h.delete(:"\n")
      h[:bb_class] = h.delete(:class) #reserved ruby functions
      h[:bb_new] = h.delete(:new)
      p = BestBuyPrinter.new(h)
      p.save
    end
    sleep(0.2) # 5 reqs / sec
    break if (r = r.next_results).nil?
  end
end