module Node
  def utility
    f = Factor.find_by_product_id_and_product_type(self.product_id,$model.name)
    $model::ContinuousFeatures.map{|feat|f.send(feat.intern)}.sum
  end
end