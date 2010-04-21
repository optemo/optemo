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
    relevant_fields = ["PRODUCT_NAME", "BRAND", "SPECIES", "FEATURE", "COLOR RANGE", "WIDTH", "PRICE", "RegularPrice", "MINIORDER_SQ_FT", "MINIORDER", "MINIORDER_SQ_FT", "PRICE_UNIT", "WARRANTY", "BRAND", "THICKNESS", "SIZE", "FINISH", "PROFIT_MARGIN", "OVERALLRATING", "AGGREGATE_DESC", "IMAGELINK", "CATEGORY_ID"]
    relevant_categories = ["8804","6950"] # These, as discovered empirically, are the hardwood flooring categories in the XML
    colorrange_to_float_map = { "Brown" => "0", "Natural" => "0", "None" => "0", "Red" => "0", "Beige/Tan" => "0", "Orange/Amber" => "0", "Gray" => "0", "Black" => "0", "Natural/Gold" => "0", "Green" => "0", "Yellow/Gold" => "0", "White" => "0"}
    species_to_hardness_map = {"Oak" => "1300", "Canadian Hard Maple" => "1450", "Red Oak" => "1290", "White Oak" => "1360", "Brazilian Cherry" => "2350", "None" => "", "Santos Mahogany" => "2200", "Tigerwood" => "1850", "Brazilian Walnut" => "3684", "White Ash" => "1320", "Maple" => "1450", "Taun" => "1900", "Alder" => "590", "Jatoba" => "2350", "Asian Mahogany" => "1520", "Hickory" => "1820", "Mongolian Teak" => "1155", "Teak" => "1155", "Manchuria Cherry" => "2350", "Cherry" => "2350", "Acacia" => "1750", "Australian Cypress" => "1375", "Hevea" => "960", "Merbau" => "1925", "Birch" => "1100", "Beech" => "1300", "Apple" => "1730", "Walnut" => "1010"}
    
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
      record.delete("miniorder_sq_ft")
      Flooring.new(record)
    end
    puts 'Finished making new records'
    Flooring.transaction do
      flooring_activerecords.each(&:save)
    end
    puts 'Done importing'
  end
end
