class ProductAndSpec
  attr_accessor :id
  def initialize(params = {})
    @id = params[:id]
  end
  
  def self.from_storage(storage)
    #Handle straight sql query from search_products
    if storage.length == 3
      product_id, names_in, vals_in = storage
      names_in += ",id"
      vals_in += ",#{product_id}"
    else
      names_in, vals_in = storage
    end
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