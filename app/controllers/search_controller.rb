class SearchController < ApplicationController
  def filter
    myfilter = params[:myfilter]
    if myfilter.nil?
      #No post info passed
      flash[:error] = "Search could not be completed."
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+params[:path_info].join('/')
    else
      mysession = Session.find(session[:user_id])
      #Allow for multiple brands
      new_brand = myfilter[:brand]
      if !myfilter[:Xbrand].blank?
        #Remove a brand
        myfilter[:brand] = mysession.brand.split('*').delete_if{|b|b == myfilter[:Xbrand]}.join('*')
      elsif new_brand != "All Brands" && new_brand != "Add Another Brand"
        old_brand = mysession.brand
        #Add a brand
        if myfilter[:brand].nil?
          myfilter[:brand] = old_brand if old_brand != "All Brands" && old_brand != "Add Another Brand"
        else
          myfilter[:brand]+= '*'+old_brand if !old_brand.blank? && old_brand != "All Brands" && old_brand != "Add Another Brand"
        end
      elsif new_brand == "Add Another Brand"
        myfilter[:brand] = mysession.brand
      end
      myfilter.delete('Xbrand') if myfilter[:Xbrand]
      
      #Delete blank values
      myfilter.delete_if{|k,v|v.blank?}
      myfilter.each_pair {|key, val| myfilter[key] = val.to_f if key.index('_min') || key.index('_max')}
      #debugger
      
      #Find clusters that match filtering query
      clusters = (mysession.product_type+'Cluster').constantize.find_all_by_layer(1)
      clusters.delete_if{|c| c.isEmpty(myfilter,mysession.product_type)}
      unless clusters.empty?
        myfilter[:filter] = true
        #Save search values
        mysession.update_attributes(myfilter)
        redirect_to "/#{session[:productType].pluralize.downcase}/list/"+clusters.map{|c|c.id}.join('/')
      else
        flash[:error] = "No products found."
        redirect_to "/#{session[:productType].pluralize.downcase}/list/"+params[:path_info].join('/')
      end
    end
  end
  
  def find
    mysession = Session.find(session[:user_id])
    #Send search query
    c = CQuery.new(session[:productType], params[:path_info].map{|p|p.to_i}, mysession, params[:search]) #C-code wrapper
    if c.valid
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+c.to_s+"/s/#{URI.encode(params[:search])}"
    else
      flash[:error] = c.to_s
      redirect_to "/#{session[:productType].pluralize.downcase}/list/"+params[:path_info].join('/')
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
        #myfilter.delete_if {|key, val| (key.index('_max') || key.index('_min'))&&!key.index(Regexp.union(session[:productType].constantize::ContinuousFeatures+["price"]))}
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
      send_query(q)
    end

    def send_query(q)
      myparams = q.to_yaml
      #debugger
      #Input
  #       cluster_id :array
      @output = %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/connect" "#{myparams}"]
      options = YAML.load(@output)
      #Output structure
  #      result_count :integer --now current page
  #      products :array --now current page
  #      clusters :array of array #only for filtering
  #      clusterdetails :hash
  #        cluster_id :int
  #        cluster_count :int
  #        clusters :array
  #        %feature :0,1,2,3
  #      %feature_min :int --now current page
  #      %feature_max :int --now current page
  #      %feature_hist :string --now current page

      #parse the new ids
      if options.blank? || options[:result_count].nil? || (options[:result_count] > 0 && options['products'].nil?)
        flash[:error] = "We're having problems with our database."
        options = {:result_count => 0}
      elsif options[:result_count] == 0
        flash[:error] = "No products were found"
      else
        results = options[:result_count] < 9 ? options[:result_count] : 9
        #Pop array of products and clusters
        newclusters = options.delete('clusters')
        options.delete('products')
        redirect_to "/#{!session[:productType].nil? ? session[:productType].pluralize.downcase : $DefaultProduct.pluralize.downcase}/list/"+newclusters.join('/')
      end
      mysession = Session.find(session[:user_id])
      mysession.update_attributes(options)
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
