require 'filepaths'
require 'fields'

module BtxtrLabels
  def BtxtrLabels.get_labels(cluster)
    return [cluster.id, cluster.parent_id]
  end

  def BtxtrLabels.generate_names_file(cluster)
    filename = get_names_filename(cluster)
    f = File.new(filename, "w")

    labels = get_labels(cluster)
    f.write(labels.map{|l| l.to_s()}.join(", "))
    f.write(".\n")

    Boosting_fields_ordered[$model].map\
    { |fieldname, field|
      fielddesc = field[0]

      f.write(fieldname + ": ")

      if fielddesc.class == Array
        f.write(fielddesc.map{|e| e.to_s()}.join(", "))
      elsif fielddesc.class == String
        f.write(fielddesc + '.')
      else
        raise "Invalid field desc type " + fielddesc.class.to_s()
      end

      f.write("\n")
    }

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

    products_this = cluster.nodes.map\
    {|n| $model.find(:all, :conditions => {:id => n.product_id})[0]}
    products_this = products_this.map{|p| [p, cluster.id]}

    parent_cluster_nodes = nil

    if cluster.parent_id == 0
      clusters = $clustermodel.find(:all, :conditions => {:parent_id => 0, :version => version})
      parent_cluster_nodes = clusters.map{|c| c.nodes}.flatten()
    else
      parent_cluster = $clustermodel.find(:all, :conditions => {:id => cluster.parent_id})[0]
      parent_cluster_nodes = parent_cluster.nodes
    end

    products_parent = parent_cluster_nodes.map{|n| n.product_id}.find_all\
    { |p_id|
      # Get clusters for product and version
      cluster_ids = \
      $nodemodel.find(:all, :conditions => {:product_id => p_id, :version => version}).map\
      { |n|
        n.cluster_id
      }

      cluster_id_set = Set.new(cluster_ids)
      not cluster_id_set.member?(cluster.id)
    }
    products_parent = products_parent.map\
    {|p_id| $model.find(:all, :conditions => {:id => p_id})[0]}

    products_parent = products_parent.map\
    {|p| [p, cluster.parent_id]}

    products = products_this + products_parent

    for product, cluster_id in products
      Boosting_fields_ordered[$model].map\
      { |fieldname, field|
        fielddesc = field[0]
        fieldval = product.send(fieldname.to_sym())

        if fielddesc == ['True', 'False']
          if fieldval == '1' or fieldval == 'True'
            fieldval = 'True'
          else
            fieldval = 'False'
          end
        elsif fieldval == nil
          fieldval = '?' # unknown value
        elsif fielddesc == 'text'
          if field.length() == 2 and field[1].has_key?('text_to_btxtr_fn')
            text_to_btxtr_fn = field[1]['text_to_btxtr_fn']
            fieldval = text_to_btxtr_fn(fieldval)
          else
            fieldval = default_text_to_btxtr_fn(fieldval)
          end
        end

        f.write(fieldval.to_s() + ", ")
      }
      f.write(cluster_id.to_s() + ".\n")
    end
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
