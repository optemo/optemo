require 'filepaths'

module BtxtrLabels
  def BtxtrLabels.get_labels(cluster)
    return [cluster.id, cluster.parent_id]
  end

  def BtxtrLabels.generate_names_file(cluster)
    filename = get_names_filename(cluster)
    FileUtils.mkdir_p Output_subdir
    f = File.new(filename, "w")

    labels = get_labels(cluster)
    f.write(labels.map{|l| l.to_s()}.join(", "))
    f.write(".\n")
    
    $Continuous["boost"].each do |feat|
      f.write(feat+": continuous.\n")
    end
    $Binary["boost"].each do |feat|
      f.write(feat+": True, False.\n")
    end
    $Categorical["boost"].each do |feat|
      f.write(feat+": text.\n")
    end

    f.close()
  end

  def BtxtrLabels.default_text_to_btxtr_fn(text)
    text.gsub!(/([-:,&]|#)/, ' ')
    text.gsub!(/(\w+)\.(\D|$)/, "#{$1} #{$2}")
    return text
  end

  def BtxtrLabels.generate_data_file(cluster)
    filename = get_data_filename(cluster)
    f = File.new(filename, "w")

    version = cluster.version

    products_this = cluster.nodes.map{|n| Product.find(n.product_id)}
    products_this = products_this.map{|p| [p, cluster.id]}

    parent_cluster_nodes = nil

    if cluster.parent_id == 0
      clusters = Cluster.find(:all, :conditions => {:parent_id => 0, :version => version, :product_type => $product_type})
      parent_cluster_nodes = clusters.map{|c| c.nodes}.flatten()
    else
      parent_cluster = Cluster.find(:first, :conditions => {:id => cluster.parent_id})
      parent_cluster_nodes = parent_cluster.nodes
    end

    products_parent = parent_cluster_nodes.map{|n| n.product_id}.find_all\
    { |p_id|
      # Get clusters for product and version
      cluster_ids = \
      Node.find(:all, :conditions => {:product_id => p_id, :version => version}).map\
      { |n|
        n.cluster_id
      }

      cluster_id_set = Set.new(cluster_ids)
      not cluster_id_set.member?(cluster.id)
    }
    products_parent = products_parent.map\
    {|p_id| Product.find(p_id) }

    products_parent = products_parent.map\
    {|p| [p, cluster.parent_id]}

    products = products_this + products_parent

    for product, cluster_id in products
      contspecs = ContSpec.cache_all(product.id)
      $Continuous["boost"].each do |feat|
        fieldval = contspecs[feat]
        fieldval ||= "?" #Unknown value
        f.write(fieldval.to_s+", ")
      end
      $Binary["boost"].each do |feat|
        fieldval = BinSpec.find_by_product_id_and_name(product.id, feat).value if BinSpec.find_by_product_id_and_name(product.id, feat)
        if fieldval == 1 || fieldval == true
          fieldval = "True"
        elsif fieldval.nil?
          fieldval = "?"
        else
          fieldval = "False"
        end
        f.write(fieldval+", ")
      end
      $Categorical["boost"].each do |feat|
        fieldval = CatSpec.find_by_product_id_and_name(product.id, feat).value if CatSpec.find_by_product_id_and_name(product.id, feat)
        fieldval ||= "?" #Unknown value
        fieldval = default_text_to_btxtr_fn(fieldval)
        f.write(fieldval+", ")
      end
      f.write(cluster_id.to_s() + ".\n")
    end

    f.flush()
  end

  def BtxtrLabels.train_boostexter(cluster)
    # See the boosexter README for description of commands
    boostexter_prog = Boostexter_subdir + '/boostexter'
    boostexter_args = [
        '-n', 40.to_s(), # numrounds 
        '-W', 1.to_s(), # ngram_maxlen
        '-N', 'ngram', # ngram_type
        '-S', get_filename_stem(cluster) # 'filename_stem'
        ]

    cmd_str = ([boostexter_prog] + boostexter_args).join(" ")
    IO.popen(cmd_str){|f| f.readlines()}
    
    if $?.exitstatus != 0
        raise "boostexter did not run successfully"
    end
  end
end
