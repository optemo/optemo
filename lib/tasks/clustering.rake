require 'rubygems'

desc "Clustering printer databases"
task :cluster_priter  do
     %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/hCluster" "printer"]
end

desc "Clustering camera databases"
task :cluster_camera do 
      %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/hCluster" "camera"]
end  