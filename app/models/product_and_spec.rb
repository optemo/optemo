class ProductAndSpec
  attr_accessor :id
  def initialize(params = {})
    @id = params[:id]
  end
  def set(names_in, vals_in)
    vals = vals_in.split(",")
    names_in.split(",").each_with_index do |name,i|
      begin
        debugger if vals[i].nil?
        send (name+"=").intern, vals[i].to_f
      rescue NoMethodError
        ProductAndSpec.module_eval do
          attr_accessor name.intern
        end
        send (name+"=").intern, vals[i].to_f
      end
    end
  end
  
  def self.create_specs
    Session.continuous["cluster"].each do |feat|
      attr_accessor feat.intern
    end
  end
  
  def ==(other_product)
    @id == other_product.id
  end
end