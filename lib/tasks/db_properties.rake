namespace :db do
  desc "Calculate properties of the product databases"
  task :properties => :environment do
    #Delete old db properties
    DbFeature.find(:all).each do |f|
      f.destroy
    end
    create_product_properties(Camera)
    create_product_properties(Printer)
    cache_index
  end
end

def cache_index
  #Store default starting point for printers
  $clustermodel = PrinterCluster
  $nodemodel = PrinterNode
  $featuremodel = PrinterFeatures
  $model = Printer
  current_version = $clustermodel.last.version
  cluster_ids = $clustermodel.find_all_by_parent_id_and_version(0, current_version, :order => 'cluster_size DESC').map{|c| c.id.to_s}
  s = Search.find_all_by_session_id(0)
  s.each {|s|s.destroy}
  session = Session.new({:product_type => 'Printer'})
  session.save
  search = Search.searchFromPath(cluster_ids,session.id)
  search.update_attribute('session_id',0)
  session.destroy
end

#Support methods
def create_product_properties(model)
  #Collect new properties  
  model::CategoricalFeatures.each {|name|
    f = DbFeature.new
    f.product_type = model.name
    f.feature_type = 'Categorical'
    f.name = name
    f.categories = model.valid.instock.map{|c|c.send(name.intern)}.compact.uniq.join('*')
    f.save
  }
  model::ContinuousFeatures.each {|name|
    f = DbFeature.new
    f.product_type = model.name
    f.feature_type = 'Continuous'
    f.name = name
    f.min = model.valid.instock.map{|c|c.send(name.intern)}.reject{|c|c.nil?}.sort[0]
    f.max = model.valid.instock.map{|c|c.send(name.intern)}.sort[-1]
    f.high = model.valid.instock.map{|c|c.send(name.intern)}.sort[model.valid.instock.count*0.75]
    f.low = model.valid.instock.map{|c|c.send(name.intern)}.sort[model.valid.instock.count*0.25]
    f.save
  }
  model::BinaryFeatures.each {|name|
    f = DbFeature.new
    f.product_type = model.name
    f.feature_type = 'Binary'
    f.name = name
    f.save
  }
end