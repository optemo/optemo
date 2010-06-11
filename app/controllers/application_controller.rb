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
  
  def set_locale
    I18n.locale = extract_locale
  end
  
  # Get locale code from request subdomain (like http://it.application.local:3000)
  # You have to put something like:
  #   127.0.0.1 gr.application.local
  # in your /etc/hosts file to try this out locally
  def extract_locale
    request.subdomains.first == 'fr' ? 'fr' : 'en'
  end
  
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "/usr/local/bin/rake #{task} #{args.join(' ')} --trace 2>&1 >> #{Rails.root}/log/rake.log &"
  end

  def set_model_type
    if request.domain.nil?
      url = $DefaultProduct
    else
      url = request.domain(4) # This gets anything up to www.printers.browsethenbuy.co.uk (n + 1 elements in the domain name)
    end
    load_defaults(url)
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
