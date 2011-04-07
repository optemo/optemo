class ProductAndSpec
  attr_accessor :id
  attr_accessor :dist if Session.extendednav
  def initialize(params = {})
    @id = params[:id]
  end
  
  def self.from_storage(storage)
    names_in, vals_in = storage
    p = new
    vals = vals_in.split(",")
    names_in.split(",").each_with_index do |name,i|
      debugger if vals[i].nil?
      p.instance_variable_set "@"+name, vals[i].to_f
#      rescue NoMethodError
#        ProductAndSpec.module_eval do
#          attr_accessor name.intern
#        end
    end
    p
  end
  
  def to_storage
    [instance_values.keys.join(","),instance_values.values.join(",")]
  end
  
  def hash
    @id.hash
  end
end