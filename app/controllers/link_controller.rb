class LinkController < ApplicationController
  
def create
  r = Referral.new
  r.retailer_offering_id = params[:id]
  r.product_id = r.retailer_offering.product_id
  r.product_type = session[:productType]
  r.session_id = session[:user_id]
  r.save
  redirect_to r.retailer_offering.url
end
end
