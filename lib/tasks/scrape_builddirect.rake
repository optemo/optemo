namespace :builddirect do
  desc 'Initializing environment'
  task :init => :environment do 
    config   = Rails::Configuration.new
    database = config.database_configuration[RAILS_ENV]["database"]
    desc "Using database #{database}"
  
    require 'rubygems'
    require 'nokogiri'
    # This next line is needed for number_to_currency
    include ActionView::Helpers::NumberHelper
    # This next line is for URL parsing
    require 'cgi'
  end

  desc 'Initializing flooring'
  task :flooring_init => :init do
    # This is kept as a holdover from another rake task
  end
  
  desc 'Parse builddirect XML file'
  task :parse, :fileparameter, :needs => [:flooring_init] do |t, args|
    # Open up the XML file
    ActiveRecord::Base.connection.execute("TRUNCATE floorings")
    args.with_defaults(:fileparameter => "BuildDirect_Products.xml")
    doc = Nokogiri::XML(File.open(args.fileparameter)) do |config|
      config.strict.noblanks
    end
    # Get out all the records
    all_records = doc.css("RECORD")
    flooring_records = []
    flooring_activerecords = []
    relevant_fields = ["PRODUCT_NAME", "BRAND", "SPECIES", "FEATURE", "COLOR RANGE", "WIDTH", "PRICE", "RegularPrice", "MINIORDER_SQ_FT", "MINIORDER", "MINIORDER_SQ_FT", "PRICE_UNIT", "WARRANTY", "BRAND", "THICKNESS", "SIZE", "FINISH", "PROFIT_MARGIN", "OVERALLRATING", "AGGREGATE_DESC", "IMAGELINK", "CATEGORY_ID", "PRODUCT_ID"]
    relevant_categories = ["6950"] # These, as discovered empirically, are the hardwood flooring categories in the XML
    colorrange_to_float_map = { "Brown" => "0", "Natural" => "0", "None" => "0", "Red" => "0", "Beige/Tan" => "0", "Orange/Amber" => "0", "Gray" => "0", "Black" => "0", "Natural/Gold" => "0", "Green" => "0", "Yellow/Gold" => "0", "White" => "0"}
    species_to_hardness_map = {"Oak" => "1300", "Canadian Hard Maple" => "1450", "Red Oak" => "1290", "White Oak" => "1360", "Brazilian Cherry" => "2350", "None" => "", "Santos Mahogany" => "2200", "Tigerwood" => "1850", "Brazilian Walnut" => "3684", "White Ash" => "1320", "Maple" => "1450", "Taun" => "1900", "Alder" => "590", "Jatoba" => "2350", "Asian Mahogany" => "1520", "Hickory" => "1820", "Mongolian Teak" => "1155", "Teak" => "1155", "Manchuria Cherry" => "2350", "Cherry" => "2350", "Acacia" => "1750", "Australian Cypress" => "1375", "Hevea" => "960", "Merbau" => "1925", "Birch" => "1100", "Beech" => "1300", "Apple" => "1730", "Walnut" => "1010"}
    product_type = "flooring_builddirect"
    
    all_records.each do |record|
      # File through and get out all the properties that we want. Rather than using xpath, we are using the .children call since it's (way) faster. 
      current_record = {}
      record.children.each do |attribute|
        xml_attr_name = attribute["NAME"]
        xml_data = attribute.children.children.to_s
        if relevant_fields.include?(xml_attr_name)
          case xml_attr_name
            when"PRODUCT_NAME"
              current_record["model"] = xml_data.chomp(" ")
            when "COLOR RANGE"
              current_record["colorrange"] = xml_data
              # current_record["colorrange"] = colorrange_to_float_map[xml_data] # Enable this once the color map is decided on
            else
              if xml_attr_name == "PRICE"
                current_record["pricestr"] = number_to_currency(xml_data)
              end
              if xml_attr_name == "RegularPrice" || xml_attr_name == "PRICE"
                xml_data = (xml_data.to_f * 100).to_i
              end
              hash_key = xml_attr_name.downcase
              unless current_record[hash_key]
                current_record[hash_key] = xml_data
              else
                current_record[hash_key] = current_record[hash_key] + "*" + xml_data
              end
          end
          # attribute["NAME"] is the name of the record
          # attribute.children.children is the actual data value.
        end
        current_record["instock"] = 1
      end
      # Store everything in a giant hash based on title. 
      # This allows records that have the same title to get grouped together with the hope of combining traits like style, etc.
#     hash_key = "No Color"
#     hash_key = current_record["colorrange"] if current_record["colorrange"]

      # Should define a hash key set of fields, and make it so that everything else is checked for. That is, right now colors and features are checked for, but it should be everything that isn't in the hash key.
      
      # Here we reject everything that isn't in one of the categories.
      next unless relevant_categories.include?(current_record["category_id"])
      
#      hash_key = current_record["brand"] + " " + current_record["model"] 
#      if current_record["feature"]
#        hash_key += " " + current_record["feature"]
#      else
#        hash_key += " " + current_record["aggregate_desc"] # If no features? try without it for now.
#      end
#      hash_key += " " + current_record["price"].to_s # This is probably the simplest way. Why didn't I think of this earlier?
#      unless flooring_records[hash_key]
#        flooring_records[hash_key] = Array[current_record]
#      else
#        flooring_records[hash_key].push(current_record)
#      end
      flooring_records.push(current_record)
    end
    puts 'Finished parsing XML'
    # flooring_records looks like this: { "brand title feature" => [item, item, item], "otherbrand title feature" => [item, item, item], ... }
    
    cont_spec_activerecords = []
    cat_spec_activerecords = []
    # bin_spec_activerecords = []
    
    flooring_activerecords = flooring_records.map do |record| 
      # With our hashing, items that have only, e.g., the color different will show up here together, in an array. 
      # We have to get the color, feature, size, and possibly other info out.
#      record = records[0]
#      ["colorrange", "feature", "width", "size"].each do |specific|
#        specifics = records.map{|r| r[specific] }.flatten.uniq.join(" ")
#        record[specific] = specifics
#      end
      record["title"] = record["brand"] + " " + record["model"]
      # Make miniorder the only place where data goes in the end
      record["miniorder"] = record["miniorder_sq_ft"]
      ["species","feature", "colorrange"].each {|f| record[f] = "None" unless record[f]}
      if record["species"].match("\\*")
        largest_name = ""
        record["species"].split("*").each {|r| largest_name = r if r.length > largest_name.length }
        record["species"] = largest_name
      end
      record["species_hardness"] = species_to_hardness_map[record["species"].to_s.chomp(" ")]
      
      if record["finish"].match("-") || record["finish"].match(" ")
        rec = record["finish"].split("-").map {|rp| rp.capitalize}.join(" ") # Join back with a space; this makes "Semi-gloss" into "Semi Gloss" for uniformity
        record["finish"] = rec.split(" ").map {|rp| rp.capitalize}.join(" ") # This makes entries that started "Semi gloss" into "Semi Gloss"
      end
      # Split out the record into our new DB format
      record["product_type"] = product_type
      record["mpn"] = record["product_id"]
      imgurl = CGI::unescapeHTML(record["imagelink"])
      record["imgmurl"] = imgurl
      baseurl = imgurl.split("?")[0]
      params = imgurl.split("?")[1].split("&")
      params.delete_at(0)
      params = params.join("&")
      record["imglurl"] = [baseurl, params].join("?")
      
      cat_specs = {}
      cont_specs = {}
      ["brand", "feature", "colorrange", "species", "finish"].each do |n| 
        if record[n] 
          cat_specs[n] = record[n]
        else
          cat_specs[n] = "None"
        end
      end
      ["profit_margin", "miniorder", "overallrating", "species_hardness", "thickness"].each {|n| cont_specs[n] = record[n].to_f}
      
      # At the moment, price is stored as a float instead of an integer. Treat this one separately
      cont_specs["price"] = record["price"].to_f / 100.0
      fractional_width_array = record["width"].split(" ")
      decimal_width = fractional_width_array[0].to_f
      if fractional_width_array.length > 1
        width_fraction = fractional_width_array[1].split("/")
        decimal_width += (width_fraction[0].to_f / width_fraction[1].to_f)
      end
      cont_specs["width"] = decimal_width
      
      ["miniorder_sq_ft", "feature", "species", "colorrange", "aggregate_desc", "pricestr", "overallrating", "pricestr", "price", "regularprice", "imagelink", "price_unit", "category_id", "warranty", "miniorder", "brand", "product_id", "profit_margin", "species_hardness", "width", "finish", "thickness"].each {|n| record.delete(n)}
      
      # Now we want products and specs separately.
      # need separate lines to save the id.
      product_activerecord = Product.new(record)
      product_activerecord.save
      
      cont_specs.each do |name, value|        
        next if value.nil?
        current_spec = {}
        current_spec["product_id"] = product_activerecord.id
        current_spec["product_type"] = product_type
        current_spec["name"] = name
        current_spec["value"] = value.to_f
        cont_spec_activerecords.push(ContSpec.new(current_spec))
      end
      cat_specs.each do |name, values|
        next if value.nil?
        values.split("*").each do |val|
          current_spec = {}
          current_spec["product_id"] = product_activerecord.id
          current_spec["product_type"] = product_type
          current_spec["name"] = name
          current_spec["value"] = val
          cat_spec_activerecords.push(CatSpec.new(current_spec))
        end
      end
    end
    puts 'Finished making and saving new product records'
    ContSpec.transaction do
      cont_spec_activerecords.each(&:save)
    end
    CatSpec.transaction do
      cat_spec_activerecords.each(&:save)
    end
    puts 'Done importing specs; Done importing'
  end
end
