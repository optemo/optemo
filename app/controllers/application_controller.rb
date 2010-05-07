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
      product_type = $DefaultProduct
    else
      product_type = case request.domain(2).split(".").first
      when "cameras"
        "camera"
      when "printers"
        "printer_us"
      when "flooring", "builddirect"
        "flooring_builddirect"
      when "laptops", "walmart"
        "laptop_walmart"
      else
        $DefaultProduct
      end  
    end
    load_defaults(product_type)
  end
  
  def update_user
    mysession = Session.find_by_id(session[:user_id])
    if mysession.nil?
      mysession = Session.new
      mysession.ip = request.remote_ip
      mysession.save
      session[:user_id] = mysession.id
    end
    
    #Check for keyword search
    if mysession.filter && mysession.searches.last
      mysession.keywordpids = mysession.searches.last.searchpids 
      mysession.keyword = mysession.searches.last.searchterm
    else
      mysession.keywordpids = nil
      mysession.keyword = nil
    end

    mysession.version = Cluster.find_last_by_product_type($product_type).version
    Session.current = mysession
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
