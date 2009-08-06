class ContentController < ApplicationController
layout 'optemo', :except => ['request']

def sitemap
  @products = $model.valid
end
end
