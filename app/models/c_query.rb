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
  attr_reader :result_count, :products, :cluster_ids, :product_type, :filterinfo, :clustergraph, :subclusters, :desc
  
  def initialize(product_type, clusters=nil)
    @cluster_ids = clusters
    @product_type = product_type
    if clusters.nil?
      myparams = {"product_name" => @product_type.downcase}.to_yaml
    else
      myparams = {"cluster_id" => @cluster_ids, "product_name" => @product_type.downcase}.to_yaml
    end
    output = sendCQuery myparams
    #debugger
    processOutput output
  end
  
  def to_s
    @cluster_ids.join("/")
  end
  
  private
  
  def sendCQuery(myparams)
    #output = %x["#{RAILS_ROOT}/lib/c_code/clusteringCode/codes/connect" "#{myparams}"]
    #YAML.load(output)
    options = {'result_count' => 420, 'products' => [14,15,16,31,25,19,20,21,22], 'clusters' => [450,451,446,449,447,444,445,448,443], 
      'clusterdetails' => [{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1},{'cluster_id' => 450, 'cluster_count' => 10, 'clusters' => [450,451,446,449,447,444,445,448,443], 'ppmfeature' => 1}],
      'ppm_max' => 24, 'ppm_min' => 4, 'itemwidth_min' => 12, 'itemwidth_max' => 2000, 'paperinput_min' => 100, 'paperinput_max' => 500,
      'resolutionarea_min' => 600, 'resolutionarea_max' => 3000000, 'price_min' => 8000, 'price_max' => 800000}
  end
  
  def processOutput(output)
    #validateOutput
    if output.blank? || output['result_count'].nil? || (output['result_count'] > 0 && output['products'].nil?)
      flash[:error] = "We're having problems with our database."
      @result_count = 0
    elsif output['result_count'] == 0
      flash[:error] = "No products were found"
      @result_count = 0
    else
      #Pop array of products and clusters
      newproducts = output.delete('products')
      @cluster_ids ||= output.delete('clusters') #Might not be needed since clusters were passed in
      @products = []
      results = output['result_count'] < 9 ? output['result_count'] : 9
      results.times do 
        @products << @product_type.constantize.find(newproducts.pop)
      end
      processClusterDetails(output.delete('clusterdetails'))
      @result_count = output.delete('result_count')
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
        @subclusters << myc.delete('clusters').join('/')
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
      myclustergraph << [mymin.round(2),(mymax-mymin).round(2)]
    end
    myclustergraph
  end
end
