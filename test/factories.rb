##Create our 16 products
FactoryGirl.define do
  factory :product do
    sequence(:id) {|n| n + 1} #Plus one as id 1 is in the fixtures
  end
end
#
#Factory.define :cluster do |c|
#  c.product_type 'printer_lph'
#  c.version '0'
#end
#
#Factory.define :node do |n|
#  n.product_type 'printer_lph'
#  n.version '0'
#  n.association :cluster
#  n.association :product
#end
#
#Factory.define :cont_spec do |s|
#  s.product_type 'printer_lph'
#end
#
#def init_facts
#  Session.new("laserprinterhub.com")
#  Session.version = 0
#  products = [nil] #Index numbering should start with 1
#  16.times do
#    products << Factory(:product)
#  end
#  
#  # Cluster Structure
#
#  #              0
#  #  1  2  3  4  5  6  7  8  9
#  #     11 12          10
#  #        13
#  
#  #Assumes db entires to increment by 2
#  clusters = [nil] #Index numbering should start with 1
#  9.times do
#    clusters << Factory(:cluster, :layer => 1, :parent_id => 0)
#  end
#  clusters << Factory(:cluster, :layer => 2, :parent_id => clusters[7].id)
#  clusters << Factory(:cluster, :layer => 2, :parent_id => clusters[2].id)
#  clusters << Factory(:cluster, :layer => 2, :parent_id => clusters[3].id)
#  clusters << Factory(:cluster, :layer => 3, :parent_id => clusters[12].id)
#
#  #Leaf nodes
#  2.times {clusters << Factory(:cluster, :layer => 3, :parent_id => clusters[10].id)}
#  3.times {clusters << Factory(:cluster, :layer => 3, :parent_id => clusters[11].id)}
#  2.times {clusters << Factory(:cluster, :layer => 3, :parent_id => clusters[12].id)}
#  3.times {clusters << Factory(:cluster, :layer => 4, :parent_id => clusters[13].id)}
#
#  #Nodes
#  Factory(:node, :product => products[1],   :cluster => clusters[1])
#  Factory(:node, :product => products[2],   :cluster => clusters[2])
#  Factory(:node, :product => products[3],   :cluster => clusters[3])
#  Factory(:node, :product => products[4],   :cluster => clusters[4])
#  Factory(:node, :product => products[5],   :cluster => clusters[5])
#  Factory(:node, :product => products[6],   :cluster => clusters[6])
#  Factory(:node, :product => products[7],   :cluster => clusters[7])
#  Factory(:node, :product => products[8],   :cluster => clusters[8])
#  Factory(:node, :product => products[9],   :cluster => clusters[9])
#  Factory(:node, :product => products[10],  :cluster => clusters[2])
#  Factory(:node, :product => products[11],  :cluster => clusters[3])
#  Factory(:node, :product => products[12],  :cluster => clusters[7])
#  Factory(:node, :product => products[13],  :cluster => clusters[3])
#  Factory(:node, :product => products[14],  :cluster => clusters[3])
#  Factory(:node, :product => products[15],  :cluster => clusters[2])
#  Factory(:node, :product => products[16],  :cluster => clusters[3])
#  Factory(:node, :product => products[7],   :cluster => clusters[10])
#  Factory(:node, :product => products[12],  :cluster => clusters[10])
#  Factory(:node, :product => products[2],   :cluster => clusters[11])
#  Factory(:node, :product => products[10],  :cluster => clusters[11])
#  Factory(:node, :product => products[15],  :cluster => clusters[11])
#  Factory(:node, :product => products[3],   :cluster => clusters[12])
#  Factory(:node, :product => products[11],  :cluster => clusters[12])
#  Factory(:node, :product => products[13],  :cluster => clusters[12])
#  Factory(:node, :product => products[14],  :cluster => clusters[12])
#  Factory(:node, :product => products[16],  :cluster => clusters[12])
#  Factory(:node, :product => products[3],   :cluster => clusters[13])
#  Factory(:node, :product => products[11],  :cluster => clusters[13])
#  Factory(:node, :product => products[16],  :cluster => clusters[13])
#  Factory(:node, :product => products[7],   :cluster => clusters[14])
#  Factory(:node, :product => products[12],  :cluster => clusters[15])
#  Factory(:node, :product => products[2],   :cluster => clusters[16])
#  Factory(:node, :product => products[10],  :cluster => clusters[17])
#  Factory(:node, :product => products[15],  :cluster => clusters[18])
#  Factory(:node, :product => products[13],  :cluster => clusters[19])
#  Factory(:node, :product => products[14],  :cluster => clusters[20])
#  Factory(:node, :product => products[3],   :cluster => clusters[21])
#  Factory(:node, :product => products[11],  :cluster => clusters[22])
#  Factory(:node, :product => products[16],  :cluster => clusters[23])
#end
#