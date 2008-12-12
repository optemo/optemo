class SearchController < ApplicationController
  
  def filter
    myfilter = params[:myfilter]
    #Remove quotes for strings
    myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
    myfilter['ids'] = 0
    newids = call_c(myfilter)
    
    redirect_to "/cameras/list/#{newids.join('/')}"
  end
  
  def sim
    #Session Tracking
    s = Similar.new
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    #Cleanse pos to be one digit
    params[:pos] = params[:pos].gsub(/[^0-8]/,'')[0,1]
    s.session_id = session[:user_id]
    s.camera_id = params[:id]
    s.save
    
    newids = call_c({"ids" => params[:id]})
    redirect_to "/cameras/list/#{newids.join('/')}"
  end
  
  private
  
  def call_c(opts = {})
    #Find current search
    @search = Search.find(session[:user_id]).search
    myfilter = @search.attributes
    myfilter.update(opts)
    myparams = myfilter.to_yaml
    output = %x["/optemo/site/lib/c_code/connect" "#{myparams}"]
    options = YAML.load(output)
    #parse the new ids
    newids = options.delete('ids')
    @search = Session.find(session[:user_id]).search
    @search.update_attributes(options)
  end
end
