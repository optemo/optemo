class SearchController < ApplicationController
  helper :search
  def filter
    myfilter = params[:myfilter]
    #Remove quotes for strings
    myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
    myfilter['camid'] = 0
    myfilter['layer'] = 1
    newids = search(myfilter)
    redirect_to "/cameras/list/#{newids.join('/')}"
  end
  
  def index
    newids = search({"layer" => 1})
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
    chosen = YAML.load(Session.find(session[:user_id]).search.chosen)
    session[:message] = ""
    txt = ""
    c = chosen.find{|c| c[:id].to_s == params[:id]}
    if !c.nil?
        c.delete('id')
        c.each_pair {|k,v| 
          if v == 0
            c.delete(k) 
          else
            c[k] = v>0 ? 'high' : 'low'
          end}
        att = c.to_a.each{|a|a.reverse!}
        session[:message] = "You are viewing cameras that have " + combine_list(att)
    end
    newids = search({"camid" => params[:id].to_i, "layer" => 2})
    redirect_to "/cameras/list/#{newids.insert(params[:pos].to_i,params[:id]).join('/')}"
  end
  
  private
  
  def search(opts = {})
    #Find current search
    @search = Session.find(session[:user_id]).search
    myfilter = @search.attributes
    myfilter.delete('chosen')
    myfilter.delete('id')
    myfilter.update(opts)
    myparams = myfilter.to_yaml
    output = %x["/optemo/site/lib/c_code/connect" "#{myparams}"]
    options = YAML.load(output)
    #parse the new ids
    newids = options.delete('ids')
    #make chosen a YAML
    options[:chosen] = options[:chosen].to_yaml
    @search = Session.find(session[:user_id]).search
    @search.update_attributes(options)
    newids
  end
  
  def combine_list(a)
    if a.length == 1
      return a[0].join(' ')+'.'
    else
      ret = " and #{a.pop.join(' ')}."
      a.each {|i| ret = i.join(' ') + ', ' + ret }
      ret
    end
  end
end
