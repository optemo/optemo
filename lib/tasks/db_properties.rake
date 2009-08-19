namespace :db do
  desc "Calculate properties of the product databases"
  task :properties => :environment do
    #Delete old db properties
    DbFeature.find(:all).each do |f|
      f.destroy
    end
    create_product_properties(Camera,"us")
    create_product_properties(Printer,"us")
    create_product_properties(Camera,"ca")
    create_product_properties(Printer,"ca")
    cache_index
  end
end

def cache_index
  #Store default starting point for printers
  $clustermodel = PrinterCluster
  $nodemodel = PrinterNode
  $featuremodel = PrinterFeatures
  $model = Printer
  $region = 'us'
  current_version = $clustermodel.find_last_by_region("us").version
  cluster_ids = $clustermodel.find_all_by_parent_id_and_version_and_region(0, current_version, "us", :order => 'cluster_size DESC').map{|c| c.id.to_s}
  s = Search.find_all_by_session_id(0)
  s.each {|s|s.destroy}
  session = Session.new({:product_type => 'Printer'})
  session.save
  search = Search.createFromPath(cluster_ids,session.id)
  search.session_id = 0
  search.save
  session.destroy
end

#Collect new properties
def create_product_properties(model,region)
  #Collect valid products
  if region == "us"
    products = model.valid.instock
  else
    products = model.valid.instock_ca
  end
  unless products.nil? || products.empty?
    model::CategoricalFeaturesF.each {|name|
      f = DbFeature.new
      f.product_type = model.name
      f.feature_type = 'Categorical'
      f.name = name
      f.region = region
      f.categories = products.map{|c|c.send(name.intern)}.compact.uniq.join('*')
      f.save
    }
    model::ContinuousFeaturesF.each {|name|
      f = DbFeature.new
      f.product_type = model.name
      f.feature_type = 'Continuous'
      f.name = name
      f.region = region
      f.min = products.map{|c|c.send(name.intern)}.reject{|c|c.nil?}.sort[0]
      f.max = products.map{|c|c.send(name.intern)}.sort[-1]
     #f.hhigh = products.map{|c|c.send(name.intern)}.sort[products.count*0.85]
      f.high = products.map{|c|c.send(name.intern)}.sort[products.count*0.6]
      f.low = products.map{|c|c.send(name.intern)}.sort[products.count*0.4]
     #f.llow = products.map{|c|c.send(name.intern)}.sort[products.count*0.15]
      f.save
    }
    model::BinaryFeaturesF.each {|name|
      f = DbFeature.new
      f.product_type = model.name
      f.feature_type = 'Binary'
      f.name = name
      f.region = region
      f.save
    }
  end
end