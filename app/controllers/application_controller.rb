# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  #
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f613bda42e728a55dc8f0670fc000291'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  before_filter :update_user, :set_locale
  
  private
  
  # Get locale code from request subdomain (like http://it.application.local:3000)
  # You have to put something like:
  #   127.0.0.1 gr.application.local
  # in your /etc/hosts file to try this out locally
  def set_locale
    I18n.locale = request.subdomains.first == 'fr' ? 'fr' : 'en'
  end

  def update_user
    #No more cookies
    #mysession_id = session[:user_id]
    #ab_testing_type = session[:ab_testing_type]
    #if mysession_id.nil?
    #  new_user = User.create
    #  # Put AB testing logic here. Set to 0 for now.
    #
    #  ab_testing_type = new_user.ab_testing_type = 0
    #  mysession_id = new_user.id
    #  session[:user_id] = mysession_id
    #  session[:ab_testing_type] = ab_testing_type
    #end
    # request.domain gets anything up to www.printers.browsethenbuy.co.uk (n + 1 elements in the domain name)
    # request.env["REMOTE_HOST"] is necessary when doing embedding
    # request.domain(4) || request.env["REMOTE_HOST"]
    # As of July 11, we are using the category id that gets passed in instead
    s = Session.new(params[:category_id]) 
    #s.id = mysession_id
    #s.ab_testing_type = ab_testing_type
  end
end
