class CQuery
  #C code Output structure
#        result_count :integer --now current page
#        products :array --now current page
#        clusters :array  #only for filtering
#        clusterdetails : array of hash
#          cluster_id :int
#          cluster_count :int
#          clusters :array
#          %feature :0,1,2,3
#        %feature_min :int --now current page
#        %feature_max :int --now current page
#        %feature_hist :string --now current page
  attr_reader :result_count, :cluster_count, :products, :cluster_ids, :product_type, :filterinfo, :clustergraph, :subclusters, :desc
  
  def initialize(product_type, clusters=nil, session=nil, searchterm=nil)
    @cluster_ids = clusters
    @product_type = product_type
    if clusters.nil?
      myparams = {"product_name" => @product_type.downcase}.to_yaml
    else
      if session.nil?
        @msg = "Please supply a session"
        return
      end
      myfilters = session.attributes.delete_if {|key, val| !key.index(/#{@product_type.constantize::MainFeatures.join('|')+"|price|brand"}/)}
      if searchterm.nil?
        myparams = {"cluster_id" => @cluster_ids, "product_name" => @product_type.downcase}.merge(myfilters).to_yaml
      else
        sphinx = searchSphinx(searchterm)
        search_ids = sphinx.results.delete_if{|r|r.class.name != @product_type || !r.myvalid?}.map{|r|r.id}
        #search_ids = sphinx.results.map{|r| r[1]} #Remove Classname from results
        if sphinx.count == 0
          @msg = "No results found."
          return
        end
        myparams = {"cluster_id" => @cluster_ids, "product_name" => @product_type.downcase, "search_ids" => search_ids, "search_count" => sphinx.count}.merge(myfilters).to_yaml
      end
    end
    output = sendCQuery myparams
    processOutput output
  end
  
  def to_s
    unless @msg.nil?
      @msg
    else
      @cluster_ids.join("/")
    end
  end
  
  def valid
    return @msg.nil?
  end
  
  private
  
  def sendCQuery(myparams)
    output = %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/connect" "#{myparams}"]
    #debugger
    YAML.load(output)
    #options = {'result_count' => 420, 'products' => [14,15,16,31,25,19,20,21,22], 'clusters' => [450,451,446,449,447,444,445,448,443], 
    #  'clusterdetails' => [{'cluster_id' => 450, 'cluster_count' => 10, 'children' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1}],
    #  'ppm_max' => 24, 'ppm_min' => 4, 'itemwidth_min' => 12, 'itemwidth_max' => 2000, 'paperinput_min' => 100, 'paperinput_max' => 500,
    #  'resolutionarea_min' => 600, 'resolutionarea_max' => 3000000, 'price_min' => 8000, 'price_max' => 800000}
  end
  
  def processOutput(output)
    #validateOutput
    if output.blank? || output['result_count'].nil? || (output['result_count'] > 0 && output['products'].nil?)
      @msg = "We're having problems with our database."
      @result_count = 0
      @cluster_count = 0
    elsif output['result_count'] == 0
      @msg = "No products were found"
      @result_count = 0
      @cluster_count = 0
    else
      #Pop array of products and clusters
      @cluster_ids ||= output.delete('clusters') #Might not be needed since clusters were passed in
      @result_count = output.delete('result_count')
      @products = output.delete('products').map{|p|@product_type.constantize.find(p)}
      @cluster_count = @products.length
      details = output.delete('clusterdetails')
      processClusterDetails(details) if details
      @filterinfo = output
    end
  end
  
  def processClusterDetails(details)
    @desc = []
    @subclusters = []
    @clustergraph = []
    details.each do |myc|
      if myc.nil?
        #Otherwise fill in a null value
        @desc << nil
      else
        #Find the cluster's description
        cluster_id = myc.delete('cluster_id')
        realc = (@product_type+"Cluster").constantize.find(cluster_id)
        @clustergraph << calcClusterGraph(realc)
        children = myc.delete('children')
        if children.nil?
          @subclusters << nil
        else
          @subclusters << children.join('/')
        end
        @desc << myc.to_a
      end
    end
  end
  
  def calcClusterGraph(cluster)
    myclustergraph = []
    (@product_type.constantize::MainFeatures+["price"]).each do |name|
      min = name+'_min'
      max = name+'_max'
      if name == "price"
          prop = DbProperty.find_by_name(@product_type)
          fmax = prop.price_max
          fmin = prop.price_min
      else
          feat = DbFeature.find_by_name(name)
          fmax = feat.max
          fmin = feat.min
      end
      #Normalize features values
      mymin = (cluster.send(min.intern) - fmin) / (fmax - fmin)
      mymax = (cluster.send(max.intern) - fmin) / (fmax - fmin)
      myclustergraph << [mymin.round(2),(mymax-mymin+0.05).round(2)]
    end
    myclustergraph
  end
  
  def searchSphinx(searchterm)
    search = Ultrasphinx::Search.new(:query => searchterm, :per_page => 10000)
    search.run
    if false
      flash[:error] = "No products were found"
      redirect_to "/#{session[:productType].pluralize.downcase || $DefaultProduct.pluralize.downcase}/list/"
    end
    search
  end
end
