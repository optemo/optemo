# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'f613bda42e728a55dc8f0670fc000291'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  before_filter :update_user
  
  private
  
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "/usr/local/bin/rake #{task} #{args.join(' ')} --trace 2>&1 >> #{Rails.root}/log/rake.log &"
  end
  
  def update_user
   if !session[:user_id].blank? && Session.exists?(session[:user_id])
      #Update loaded time
      @mysession = Session.find(session[:user_id])
      @mysession.loaded_at = Time.now
      @mysession.save
   else
      #Create a new session
      @mysession = Session.new
      @mysession.loaded_at = Time.now
      @mysession.save
      session[:user_id] = @mysession.id
      #Create a new search object for the session
      @mysearch = Search.new
      @mysearch.session = @mysession
      @mysearch.save
    end
  end
  
  def initialize_search(params = {})
    if session[:search_id]
      atts = Search.find(session[:search_id]).attributes
      "i0".upto("i8") {|i| atts.delete(i)} 
      "c0".upto("c8") {|i| atts.delete(i)}
      atts.delete('camera_id')
      atts.delete('cluster_id')
      atts.delete('result_count')
      atts.delete('id')
      atts.delete('chosen')
      s = Search.new(atts.merge(params))
      s.parent_id = session[:search_id]
    else
      s = Search.new(params)
      s.session_id = session[:user_id]
    end
    s
  end
end
