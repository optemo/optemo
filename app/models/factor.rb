class Factor < ActiveRecord::Base
  # Gets the precalculated factors, fetching them if they don't exist.
  def self.factors(productid)
    unless defined? @@prefetched_factors
      @@prefetched_factors = {}
      Factor.find_all_by_product_type($model.name).compact.each {|f| @@prefetched_factors[f.product_id] = f}
    end
    @@prefetched_factors[productid]
  end
end
