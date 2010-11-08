class ContentController < ApplicationController
layout 'optemo', :except => ['request']

def sitemap
  @products = Product.valid
end

def name
  render :name, :layout => false
end

def socket
  render :socket, :layout => false
end

def create_request
  fr = FeatureRequest.new(params[:request])
  fr.session_id = Session.current.id
  fr.save
  render :text => "Thank you for submitting your comment"
end

end
