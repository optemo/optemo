class SearchController < ApplicationController
  def filter
    s = initialize_search
    s.cluster_id = nil
    s.product_id = nil
    myfilter = params[:myfilter]
    #Allow for multiple brands
    new_brand = myfilter[:brand]
    #debugger
    if !myfilter[:Xbrand].blank?
      #Remove a brand
      myfilter[:brand] = Search.find(s.parent_id).brand.split('*').delete_if{|b|b == myfilter[:Xbrand]}.join('*')
    elsif new_brand != "All Brands" && new_brand != "Add Another Brand"
      old_brand = Search.find(s.parent_id).brand
      #Add a brand
      if myfilter[:brand].nil?
        myfilter[:brand] = old_brand if old_brand != "All Brands" && old_brand != "Add Another Brand"
      else
        myfilter[:brand]+= '*'+old_brand if !old_brand.blank? && old_brand != "All Brands" && old_brand != "Add Another Brand"
      end
    elsif new_brand == "Add Another Brand"
      myfilter[:brand] = Search.find(s.parent_id).brand
    end
    myfilter.delete('Xbrand') if myfilter[:Xbrand]
    myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
    s.attributes = myfilter
    s.filter = session[:search_id]
    search(s)
  end
  
  def index
    s = initialize_search
    search(s)
  end
  
  def sim
    #Create new search instance
    s = initialize_search
    s.filter = params[:f]
    if params[:c].nil?
      #The data has not previously been clustered
      s.product_id = params[:id]
      search(s,{"product_id" => params[:id].to_i})
    else
      #The data has previously been clustered
      @session = Session.find(session[:user_id])
      #Cleanse id to be only numbers
      s.product_id = params[:id].gsub(/\D/,'')
      s.cluster_id = params[:c].gsub(/\D/,'')
      #Generate NLG message
      chosen = YAML.load(@session.chosen)
      #debugger
      c = chosen.find{|c| c[:cluster_id] == s.cluster_id} if chosen
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
            @session.msg = ""
          else
            att = c.to_a.each{|a|a.reverse!}
            @session.msg = "which have " + combine_list(att)
          end
      end
      @session.save
      search(s,{"cluster_id" => s.cluster_id})
    end
  end
  
  def find
    @search = Ultrasphinx::Search.new(:query => params[:search])
    @search.run
    @search.results
    #s = initialize_search
    @session = Session.find(session[:user_id])
    @session.result_count = @search.count > 9 ? 9 : @search.count
    if @session.result_count == 0
      flash[:error] = "No products were found"
      redirect_to "/#{session[:productType].pluralize.downcase || $DefaultProduct.pluralize.downcase}/list/"
    else
      @session.msg = "Search results for: "+params[:search]
      "i0=".upto("i8=") do |i|
        @session.send i.intern, @search.shift.id unless @search.empty?
      end
      @session.save
      redirect_to "/products/list/"+@session.URL
    end
  end
  
  private
  
  def search(s, opts = {})
    q = {}
    if s.filter && s.filter > 1
      if !session[:search_id].nil? && s.filter != session[:search_id]
        myfilter = Search.find(s.filter).attributes
        s.parent_id = s.filter
      else
        myfilter = s.attributes
      end
      #Remove unnescessary arguments from YAML query
      myfilter.delete('id')
      myfilter.delete('parent_id')
      myfilter.delete('session_id')
      myfilter.delete('created_at')
      myfilter.delete('updated_at')
      myfilter.delete('filter')
      myfilter.delete('brand') if myfilter['brand'].blank?
      #myfilter.delete_if {|key, val| (key.index('_max') || key.index('_min'))&&!key.index(Regexp.union(session[:productType].constantize::MainFeatures+["price"]))}
      if session[:productType] == 'Printer'
        myfilter.delete_if {|key, val| (key.index('_max') || key.index('_min'))&&!key.index(/ppm|itemwidth|paperinput|price/)}
      else
        myfilter.delete_if {|key, val| (key.index('_max') || key.index('_min'))&&!key.index(/maximumresolution|displaysize|opticalzoom|price/)}
      end
      myfilter.delete('product_id') if myfilter['cluster_id']
      myfilter.delete('cluster_id') unless myfilter['cluster_id']
      myfilter.delete('product_id') unless myfilter['product_id']
      q.update(myfilter)
    end
    q.update(opts)
    q.update({'cluster_id' => s.cluster_id}) if s.cluster_id
    s.update_attributes(q)
    session[:search_id] = s.id
    #Make request work with c code
    q['product_name'] = !session[:productType].nil? ? session[:productType].downcase : $DefaultProduct.downcase
    #q['brand'] = q['brand'].split('*').first if !q['brand'].nil? #Remove first later
    myparams = q.to_yaml
    #debugger
    @output = %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/connect" "#{myparams}"]
    options = YAML.load(@output)
    #parse the new ids
    if options.blank? || options[:result_count].nil? || (options[:result_count] > 0 && options['products'].nil?)
      flash[:error] = "We're having problems with our database."
      options = {:result_count => 0}
    elsif options[:result_count] == 0
      flash[:error] = "No products were found"
    else
      results = options[:result_count] < 9 ? options[:result_count] : 9
      newproducts = options.delete('products')
      newclusters = options.delete('clusters')
      current_node = "i0"
      results.times do 
        c = "c#{current_node[1,1]}"
        options[current_node.intern] = newproducts.pop
        options[c.intern] = newclusters.pop unless newclusters.nil? || newclusters.empty?
        current_node.next!
      end
      #make chosen a YAML
      options[:chosen] = options[:chosen].to_yaml
    end
    @session = s.session
    @session.update_attributes(options)
    redirect_to "/#{!session[:productType].nil? ? session[:productType].pluralize.downcase : $DefaultProduct.pluralize.downcase}/list/"+@session.URL
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
