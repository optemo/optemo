class ContentController < ApplicationController
layout 'optemo'

def sitemap
  @products = $model.valid
end
end
