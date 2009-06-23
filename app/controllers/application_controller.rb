require 'GlobalDeclarations'
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :title=, :full_title=, :describe=
  @description

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f613bda42e728a55dc8f0670fc000291'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  before_filter :update_user
 
  private
  $DefaultProduct = 'Printer'
  
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "/usr/local/bin/rake #{task} #{args.join(' ')} --trace 2>&1 >> #{Rails.root}/log/rake.log &"
  end
  
  def update_user
#    session[:user_id] = nil
#    return
    if session[:user_id].blank? || !Session.exists?(session[:user_id])
      #Find the user's session if there are no cookies -- doesn't work for proxy's and firewalls
      #mysession = Session.find(:first, :conditions => ['ip = ? and updated_at > ?',request.remote_ip,30.minutes.ago])
      #if mysession.nil?
        #Create a new session
        mysession = Session.new
        mysession.ip = request.remote_ip
        mysession.save
        # Create a row in every product-features table
        $ProdTypeList.each do |p|
          myProduct = (p + 'Features').constantize.new
          myProduct.session_id = mysession.id        
          myProduct.save
        end
      #else
      #  mysession.update_attribute(:updated_at, Time.now)
      #end
      session[:user_id] = mysession.id
    end
    $model = (session[:productType] || $DefaultProduct).constantize
    $nodemodel = ((session[:productType] || $DefaultProduct)+'Node').constantize
    $clustermodel = ((session[:productType] || $DefaultProduct)+'Cluster').constantize
  end
  
  def title=(title)
    @title_prefix = title
    @template.instance_variable_set("@title_prefix", @title_prefix)  # Necessary if set from view
  end
  def full_title=(title)
    @title_full = title % $SITE_TITLE
    @template.instance_variable_set("@title_full", @title_full)  # Necessary if set from view
  end
  def describe=(mydescription)
    @description = mydescription
    @template.instance_variable_set("@description", @description)  # Necessary if set from view
  end
  

end
  
  # Returns a row of the factor table
  def LookupFactorRow (pType, productId)
    return Factor.find(:first, :conditions => ['product_id = ? and product_type = ?', productId, pType])
  end

  # Calculates the Utility of a product, based on user-preferences
  # Computation:
  # For every Product,
  # => 2 Database lookups      (Can be reduced to 1)
  # => |Continuous Features| * 2 Arithmetic operations
  def CalculateUtility(p)  
    cost = 0.0
    #getFactorRow = LookupFactorRow(session[:productType], product.id)
        getFactorRow = LookupFactorRow('Printer', p.send('id'))                    # TODO:
    userSession = Session.find(:first, :conditions => ['id = ?', session[:user_id]])
    # For all features
      session[:productType].constantize::ContinuousFeatures.each do |f|
      # Multiply factor value by the User's preference for that feature (weight) and add to cost
        cost = cost + getFactorRow.send(f) * userSession.features.send("#{f}_pref")
      end      
    return cost
  end