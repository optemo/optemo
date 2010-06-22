require 'GlobalDeclarations'

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :title=, :full_title=, :describe=
  @description
  
  #
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f613bda42e728a55dc8f0670fc000291'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  before_filter :set_model_type, :update_user, :set_locale
  
  private
  
  # Get locale code from request subdomain (like http://it.application.local:3000)
  # You have to put something like:
  #   127.0.0.1 gr.application.local
  # in your /etc/hosts file to try this out locally
  def set_locale
    I18n.locale = request.subdomains.first == 'fr' ? 'fr' : 'en'
  end

  def set_model_type
    load_defaults(request.domain(4)) # This gets anything up to www.printers.browsethenbuy.co.uk (n + 1 elements in the domain name)
  end
  
  def update_user
    mysession_id = session[:user_id]
    if mysession_id.nil?
      mysession_id = Search.maximum(:session_id).to_i + 2
      session[:user_id] = mysession_id
    end

    myversion = Cluster.maximum(:version, :conditions => ['product_type = ?', $product_type])
    Session.current = Session.new(mysession_id, myversion)
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
