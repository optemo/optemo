class LinkController < ApplicationController
  include CachingMemcached
  def create
    r = Referral.new
    r.retailer_offering_id = params[:id]
    r.product_id = r.retailer_offering.product_id
    r.product_type = session[:productType]
    r.session_id = session[:user_id]
    r.save
    if r.retailer_offering.url.blank?
      redirect_to 'http://amazon.com/gp/product/'+findCachedProduct(r.product_id).asin+'?tag=optemo-20&m='+r.retailer_offering.merchant
    else
      redirect_to r.retailer_offering.url
    end
  end
end
