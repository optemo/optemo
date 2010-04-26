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

    Boosting_fields[$model].each_pair\
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

    products_this = cluster.nodes.map{|n| [n.product_id, cluster.id]}

    parent_cluster_nodes = None

    if cluster.parent_id == 0
      clusters = $clustermodel.find(:all, :conditions => {:parent_id => 0, :version => version})
      parent_cluster_nodes = clusters.map{|c| c.nodes}.flatten()
    else
      parent_cluster = $clustermodel.find(:all, :conditions => {:id => cluster.parent_id})[0]
      parent_cluster_nodes = parent_cluster.nodes
    end

    products_parent = parent_cluster_nodes.map{|n| n.product}.find_all\
    { |p|
      # Get clusters for product and version
      cluster_ids = \
      $nodemodel.find(:all, :conditions => {:product_id => p.id, :version = version}).map\
      { |n|
        n.cluster_id
      }

      cluster_id_set = Set.new(cluster_ids)
      not cluster_id_set.member?(cluster.id)
    }
    products_parent = products_parent.map{|p| [p.id, cluster.parent_id]}

    products = products_this + products_parent

    for product, cluster_id in products
      Boosting_fields[$model].each_pair\
      { |fieldname, field|
        fielddesc = field[0]
        fieldval = product.instance_variable_get(fieldname.to_sym())

        if fielddesc = ['True', 'False']
          if fieldval == '1' or fieldval == 'True'
            fieldval = 'True'
          else
            fieldval = 'False'
          end
        elsif fieldval == None
          fieldval = '?' # unknown value
        elsif fielddesc = 'text'
          if len(field) == 2 and field[1].has_key?('text_to_btxtr_fn')
            fieldval = field[1]['text_to_btxtr_fn'](fieldval)
          else
            fieldval = default_text_to_btxtr_fn(fieldval)
          end
        end

        f.write(fieldval)
      }
      f.write(cluster_id.to_s() + ".\n")
    end
  end

  def BtxtrLabels.train_boostexter(cluster)
    # See the boosexter README for description of commands
    boostexter_prog = Boostexter_subdir + 'boostexter'
    boostexter_args = [
        '-n', str(40), # numrounds 
        '-W', str(1), # ngram_maxlen
        '-N', 'ngram', # ngram_type
        '-S', get_filename_stem(cluster) # 'filename_stem'
        ]

    cmd = [boostexter_prog]
    cmd.extend(boostexter_args)

    cmd_str = ([boostexter_prog] + boostexter_args).join(" ")
    IO.popen(cmd_str){|f| f.readlines()}
    assert($?.exitstatus == 0)
  end
end
