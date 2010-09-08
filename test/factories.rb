#Create our 16 products
Factory.define :product do |p|
    p.sequence(:id) {|n| n}
end

def init_facts
  16.times do
    Factory(:product)
  end
end
