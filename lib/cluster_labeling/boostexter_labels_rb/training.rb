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

    Boosting_fields[$DefaultProduct].each_pair\
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
  end

  def BtxtrLabels.generate_data_file(cluster)
  end

  def BtxtrLabels.train_boostexter(cluster)
  end
end
