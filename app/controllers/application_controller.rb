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
  
  before_filter :set_model_type
  before_filter :update_user 
  before_filter :set_locale
  
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
      @ds = "Printer"
    else
      domainprefix = request.domain.split(".").first
      if domainprefix == "cameras"
        @ds = "Camera"
      elsif domainprefix == "printers"
        @ds = "Printer"
      else
        @ds = "Printer"
      end  
    end
    # The "|| $DefaultProduct" part will never get hit.
    $model = @ds.constantize
    $nodemodel = (@ds + 'Node').constantize
    $clustermodel = (@ds + 'Cluster').constantize
    $featuremodel = (@ds + 'Features').constantize
  end
  
  def update_user
    mysession = Session.find_by_id(session[:user_id])
    if mysession.nil?
      mysession = Session.new
      mysession.ip = request.remote_ip
      mysession.save
      # Create a row in every product-features table
      $ProdTypeList.each do |p|
        myProduct = (p + 'Features').constantize.new
        myProduct.session_id = mysession.id        
        myProduct.save
      end
      session[:user_id] = mysession.id
      @@session = mysession      
    else
      @@session = mysession
    end

    # Set some stuff in the session, etc., straight from cameras_controller.rb or printers_controller.rb
    # These need to be changed to variable names from strings
    session[:productType] = @ds
    @@session.update_attribute('product_type', @ds) if @@session.product_type.nil? || @@session.product_type != @ds

    # In addition, it seems like all of these are being set below to something else. Apparently they are no longer strings after "constantize"?
    # I would like to do memory management here to delete the object. Bug? ZAT

    $region = request.url.match(/\.ca/) ? "ca" : "us"
    @@keywordsearch = nil
    @@keyword = nil
    if @@session.filter && @@session.searches.last
      @@keywordsearch = @@session.searches.last.searchpids 
      @@keyword = @@session.searches.last.searchterm
    end
    $dbfeat = {}
    if $dbfeat.empty? 
      #debugger
      DbFeature.find_all_by_product_type_and_region($model.name,$region).each {|f| $dbfeat[f.name] = f}
    end
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
  
  def initialClusters
    @@session.clearFilters
    #Remove search terms
    @@keywordsearch = nil
    @@keyword = nil
    if $model == Printer && $region == "us" && s = Search.find_by_session_id(0)
      0.upto(s.cluster_count-1).map{|i| s.send(:"c#{i}")}
    else
      current_version = $clustermodel.find_last_by_region($region).version
      $clustermodel.find_all_by_parent_id_and_version_and_region(0, current_version, $region).map{|c| c.id}
    end
  end
end