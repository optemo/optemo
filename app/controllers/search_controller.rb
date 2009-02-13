class SearchController < ApplicationController
  def filter
    s = initialize_search
    #Remove quotes for strings
    myfilter = params[:myfilter]
    Session.find(session[:user_id]).update_attributes(myfilter)
    myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
    s.attributes = myfilter
    search(s)
  end
  
  def index
    s = initialize_search
    search(s)
  end
  
  def sim
    #Create new search instance
    s = initialize_search
    #Cleanse id to be only numbers
    params[:id].gsub!(/\D/,'')
    s.cluster_id = params[:id]
    #Generate NLG message
    chosen = YAML.load(Search.find(session[:search_id]).chosen)
    c = chosen.find{|c| c[:id].to_s == params[:id]}
    if !c.nil?
        c.delete('id')
        c.each_pair {|k,v| 
          if v == 0
            c.delete(k) 
          else
            c[k] = v>0 ? 'high' : 'low'
          end}
        if c.empty?
          s.msg = ""
        else
          att = c.to_a.each{|a|a.reverse!}
          s.msg = "You are viewing cameras that have " + combine_list(att)
        end
    end
    #Cleanse pos to be one digit
    params[:pos] = params[:pos].gsub(/[^0-8]/,'')[0,1]
    #search(s,{"cam_id" => params[:id].to_i},params[:pos])
    search(s,{"cluster_id" => params[:id].to_i},params[:pos])
  end
  
  def find
    @search = Ultrasphinx::Search.new(:query => params[:search])
    @search.run
    @search.results
    s = initialize_search
    s.msg = "Search results for: "+params[:search]
    "i0=".upto("i8=") do |i|
      s.send i.intern, @search.shift.id unless @search.empty?
    end
    s.save
    session[:search_id] = s.id
    redirect_to "/cameras/list/"+s.URL
  end
  
  private
  
  def search(s, opts = {}, pos = nil)
    #Find current search
    myfilter = s.attributes
    #Remove unnescessary arguments from YAML query
    myfilter.delete('chosen')
    myfilter.delete('id')
    "i0".upto("i8") {|i| myfilter.delete(i)} 
    "c0".upto("c8") {|i| myfilter.delete(i)} 
    myfilter.delete('parent_id')
    myfilter.delete('session_id')
    myfilter.delete('msg')
    myfilter.delete('created_at')
    myfilter.delete('updated_at')
    #myfilter['layer'] = 1
    myfilter.delete('cluster_id') unless myfilter['cluster_id']
    myfilter.update(opts)
    myparams = myfilter.to_yaml
    @badparams = "None"
    #debugger
    @output = %x["/optemo/site/lib/c_code/connect" "#{myparams}"]
    options = YAML.load(@output)
    #parse the new ids
    if options.blank? || options['cameras'].nil? || options['clusters'].nil?
      flash[:error] = "Error finding products."
      redirect_to :controller => 'cameras'
    else
      #newcameras = options.delete('ids')
      newcameras = options.delete('cameras')
      newclusters = options.delete('clusters')
      "i0".upto("i8") do |i|
        c = "c#{i[1,1]}"
        if !pos.nil? && i == "i#{pos}"
          options[i.intern] = s.cluster_id
        else
          options[i.intern] = newcameras.pop
          options[c.intern] = newclusters.pop
        end
      end
      #make chosen a YAML
      options[:chosen] = options[:chosen].to_yaml
      
      #Filter for only valid options
      options.delete_if{|k,v| if k.to_s.match(/^(cameras|clusters|maximumresolution\_max|maximumresolution\_min|displaysize\_max|displaysize\_min|opticalzoom\_max|opticalzoom\_min|price\_max|price\_min|clusters|chosen|i\d|c\d)$/).nil?
        @badparams = k.to_s
        true
      else
        false
      end
        }
      s.update_attributes(options)
      
      session[:search_id] = s.id
      redirect_to "/cameras/list/"+s.URL
    end
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
