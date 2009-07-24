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
  
  before_filter :update_user 
  
  
  @@session = nil 
  private

   
    
  
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "/usr/local/bin/rake #{task} #{args.join(' ')} --trace 2>&1 >> #{Rails.root}/log/rake.log &"
  end
  
  def update_user
    $model = (session[:productType] || $DefaultProduct).constantize
    $nodemodel = ((session[:productType] || $DefaultProduct)+'Node').constantize
    $clustermodel = ((session[:productType] || $DefaultProduct)+'Cluster').constantize
    $featuremodel = ((session[:productType] || $DefaultProduct)+'Features').constantize
   
    if session[:user_id].blank? || !Session.exists?(session[:user_id])
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
      @@session = Session.find(session[:user_id])
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
    mysession = Session.find(session[:user_id])
    mysession.clearFilters

    if $model == Printer && s = Search.find_by_session_id(0)
      path = 0.upto(s.cluster_count-1).map{|i| s.send(:"c#{i}")}.join('-')
    else
      current_version = $clustermodel.last.version
      path = $clustermodel.find_all_by_parent_id_and_version(0, current_version, :order => 'cluster_size DESC').map{|c| c.id}.join('-')
    end
    "/#{$model.urlname}/compare/"+path
  end
end