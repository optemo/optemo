namespace :builddirect do
  desc 'Initializing environment'
  task :init => :environment do 
    config   = Rails::Configuration.new
    database = config.database_configuration[RAILS_ENV]["database"]
    desc "Using database #{database}"
  
    require 'rubygems'
    require 'nokogiri'
  end

  task :flooring_init => :init do
#    include FlooringHelper
#    include FlooringConstants

    # TODO get rid of this construct:
#    $model = @@model
#    $scrapedmodel = @@scrapedmodel
#    $brands= @@brands
#    $series = @@series
#    $descriptors = @@descriptors + $conditions.collect{|cond| /(\s|^|;|,)#{cond}(\s|,|$)/i}

    # For flooring, we want: SPECIES, FEATURE, COLOR RANGE, WIDTH, PRICE, maybe RegularPrice, MINIORDER_SQ_FT, MINIORDER [one of those will be -1, depending on order type based on PRICE_UNIT], maybe WARRANTY, BRAND, THICKNESS, FINISH
    
    # Continuous features are: WIDTH, PRICE, maybe RegularPrice, MINIORDER_SQ_FT, MINIORDER, THICKNESS, maybe WARRANTY
#    $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
#       'paperinput','scanner', 'printserver', 'brand', 'model']
#    $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
#       'local_id', "product_type", "region", "retailer_id"]
  end

  task :parse, :fileparameter, :needs => [:flooring_init] do |t, args|
    # Open up the XML file
    ActiveRecord::Base.connection.execute("TRUNCATE floorings")
    args.with_defaults(:fileparameter => "BuildDirect_Products.xml")
    doc = Nokogiri::XML(File.open(args.fileparameter)) do |config|
      config.strict.noblanks
    end
    # Get out all the records
    all_records = doc.css("RECORD")
    flooring_records = {}
    flooring_activerecords = []
    relevant_fields = ["PRODUCT_NAME", "BRAND", "SPECIES", "FEATURE", "COLOR RANGE", "WIDTH", "PRICE", "RegularPrice", "MINIORDER_SQ_FT", "MINIORDER", "PRICE_UNIT", "WARRANTY", "BRAND", "THICKNESS", "SIZE", "FINISH", "PROFIT_MARGIN", "OVERALLRATING", "AGGREGATE_DESC"]
    all_records.each do |record|
      # File through and get out all the properties that we want. Rather than using xpath, we are using 
      current_record = {}
      record.children.each do |attribute|
        xml_attr_name = attribute["NAME"]
        xml_data = attribute.children.children.to_s
        if relevant_fields.include?(xml_attr_name)
          if xml_attr_name == "PRODUCT_NAME"
            current_record["title"] = xml_data.chomp(" ")
          elsif xml_attr_name == "COLOR RANGE"
            current_record["colorrange"] = xml_data
          else
            hash_key = xml_attr_name.downcase
            unless current_record[hash_key]
              current_record[hash_key] = xml_data
            else
              current_record[hash_key] = current_record[hash_key] + " " + xml_data
            end
          end
          # attribute["NAME"] is the name of the record
          # attribute.children.children is the actual data value.
        end
      end
      # Store everything in a giant hash based on title. 
      # This allows records that have the same title to get grouped together with the hope of combining traits like style, etc.
#     hash_key = "No Color"
#     hash_key = current_record["colorrange"] if current_record["colorrange"]

      
      
      # Should define a hash key set of fields, and make it so that everything else is checked for. That is, right now colors and features are checked for, but it should be everything that isn't in the hash key.
      
          
    
      hash_key = current_record["brand"] + " " + current_record["title"] 
      if current_record["feature"]
        hash_key += " " + current_record["feature"]
      else
        hash_key += " " + current_record["aggregate_desc"] # If no features? try without it for now.
      end
      unless flooring_records[hash_key]
        flooring_records[hash_key] = Array[current_record]
      else
        flooring_records[hash_key].push(current_record)
      end
    end
    desc 'Finished parsing XML'
    flooring_activerecords = flooring_records.map do |k,records| 
      # This is where we put in the features that show up multiple times. Let's browse a bit to figure out what those are.
      record = records[0]
      colors = records.map{ |r| r["colorrange"] }.uniq.join(" ")
      record["colorrange"] = colors
      features = records.map{ |r| r["feature"] }.flatten.uniq.join(" ")
      record["feature"] = features
      Flooring.new(record)
    end
    desc 'Finished making new records'
    Flooring.transaction do
      flooring_activerecords.each(&:save)
    end
    desc 'Done importing'
  end
end
