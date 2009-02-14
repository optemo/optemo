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
    if params[:c].nil?
      #The data has not previously been clustered
      s.camera_id = params[:id]
      search(s,{"camera_id" => params[:id].to_i})
    else
      #The data has previously been clustered
      #Cleanse id to be only numbers
      s.camera_id = params[:id].gsub(/\D/,'')
      s.cluster_id = params[:c].gsub(/\D/,'')
      #Generate NLG message
      chosen = YAML.load(Search.find(session[:search_id]).chosen)
      c = chosen.find{|c| c[:cluster_id].to_s == s.camera_id}
      if !c.nil?
          c.delete('cluster_id')
          c.delete('cluster_count')
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
      search(s,{"cluster_id" => s.cluster_id})
    end
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
  
  def search(s, opts = {})
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
    myfilter.delete('result_count')
    #myfilter['layer'] = 1
    myfilter.delete('camera_id') if myfilter['cluster_id']
    myfilter.delete('cluster_id') unless myfilter['cluster_id']
    myfilter.update(opts)
    myparams = myfilter.to_yaml
    @badparams = "None"
    #debugger
    @output = %x["/optemo/site/lib/c_code/connect" "#{myparams}"]
    options = YAML.load(@output)
    #parse the new ids
    if options.blank? || options[:result_count].nil? || (options[:result_count] > 0 && options['cameras'].nil?) || (options[:result_count] > 0 && options['clusters'].nil?)
      flash[:error] = "There was a problem finding your products."
      redirect_to :back
    elsif options[:result_count] == 0
      flash[:error] = "No products were found"
      redirect_to :back
    else
      options[:result_count] = 9 if options[:result_count] > 9
      newcameras = options.delete('cameras')
      newclusters = options.delete('clusters')
      current_node = "i0"
      options[:result_count].times do 
        c = "c#{current_node[1,1]}"
        options[current_node.intern] = newcameras.pop
        options[c.intern] = newclusters.pop
        current_node.next!
      end
      #make chosen a YAML
      options[:chosen] = options[:chosen].to_yaml
      
      #Filter for only valid options
      options.delete_if{|k,v| if k.to_s.match(/^(cameras|clusters|maximumresolution\_max|maximumresolution\_min|displaysize\_max|displaysize\_min|opticalzoom\_max|opticalzoom\_min|price\_max|price\_min|clusters|chosen|i\d|c\d|result\_count)$/).nil?
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
