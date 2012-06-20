def search_for(search_type, params)
# Accesses the Amazon feed and returns 10 products and their data
# The data is split into an array and returned
  associates_id = 'A3DWYIK6Y9EEQB'
  key_id = '0NHTZ9NMZF742TQM4EG2'
  is = ItemSearch.new(search_type, params)
  is.response_group = ResponseGroup.new( 'Medium', 'Images', 'ItemAttributes')
  resp = Request.new(key_id, associates_id).search( is )
  string_array = resp.item_search_response[0].to_s.gsub!("\n", '|').split('|')
end

def make_cat_spec(id, name, value)
# Creates an entry in the cat_specs table
  c = CatSpec.find_or_initialize_by_product_id_and_name(id, name)
  c.update_attributes(value: value)
end

def make_cont_spec(id, name, value)
# Creates an entry in the cont_specs table
  c = ContSpec.find_or_initialize_by_product_id_and_name(id, name)
  c.update_attributes(value: value)
end

def make_bin_spec(id, name)
# Creates an entry in the bin_specs table
  b = BinSpec.find_or_initialize_by_product_id_and_name(id, name)
  b.update_attributes(value: true)  
end

def make_text_spec(id, name, value)
# Creates an entry in the text_specs table
  t = TextSpec.find_or_initialize_by_product_id_and_name(id, name)
  t.update_attributes(value: value)
end

def create_amazon_specs(item, id)
# Creates all specs for a given item
  make_cat_spec(id, 'product_type', item['product_type'])
  make_cat_spec(id, 'amazon_sku', item['amazon_sku']) if item['amazon_sku']
  make_cat_spec(id, 'brand', item['brand']) if item['brand']
  
  make_cat_spec(id, 'mpaa_rating', item['mpaa_rating']) if item['mpaa_rating']
  make_cat_spec(id, 'format', item['format']) if item['format']
  make_cat_spec(id, 'language', item['language']) if item['language']
  
  make_cat_spec(id, 'resolution', item['resolution']) if item['resolution']
  make_cat_spec(id, 'screen_type', item['screen_type']) if item['screen_type']
  
  make_cat_spec(id, 'hd_video', item['hd_video']) if item['hd_video']
  make_cat_spec(id, 'colour', item['colour']) if item['colour']
  
  make_cat_spec(id, 'app_type', item['app_type']) if item['app_type']
  make_cat_spec(id, 'platform', item['platform']) if item['platform']
  
  make_cont_spec(id, 'price_new', item['price_new']) if item['price_new']
  make_cont_spec(id, 'price_used', item['price_used']) if item['price_used']
  
  make_cont_spec(id, 'size', item['size']) if item['size']
  make_cont_spec(id, 'ref_rate', item['ref_rate']) if item['ref_rate']
  
  make_cont_spec(id, 'mp', item['mp']) if item['mp']
  
  make_bin_spec(id, 'hdmi') if item['hdmi']
  make_bin_spec(id, '3d') if item['3d']
  
  make_text_spec(id, 'title', item['title'])
  make_text_spec(id, 'image_url_t', item['image_url_t'])
  make_text_spec(id, 'image_url_s', item['image_url_s'])
  make_text_spec(id, 'image_url_m', item['image_url_m'])
  make_text_spec(id, 'image_url_l', item['image_url_l'])
end

def save(items)
# Uploads data for all items
  retailer = "A"
  total_items = items.length
  completed = 0
    
  for item in items
    puts "Uploading to database: #{completed*100/total_items}%"
    if item['title'] # Don't upload products without names
      # Make sure not to duplicate products - check if they're already in the table
      prod = Product.find_or_initialize_by_sku_and_retailer(item['sku'], retailer)
      prod.update_attributes(instock: true)
      create_amazon_specs(item, Product.find_by_sku_and_retailer(item['sku'], retailer).id)
    end
    completed += 1
  end
  puts "Save complete: #{Product.where(retailer: retailer).length} products saved"
end

def get_scraping_rules(product_type)
# Gathers all scraping rules for a given product type as well as for the parent department (in this case ADepartments)
  scraping_rules = []
  scraping_rules << ScrapingRule.where(product_type: product_type)
  scraping_rules << ScrapingRule.where(product_type: 'ADepartments')
  scraping_rules.flatten!
end

def get_real_rule(scraping_rule)
# Parses the scraping rule and extracts the regex and any additional information
  scraping_rule.gsub!(/^\//, "")
  index = scraping_rule.index(/[^\\]\//)
  if index # If the regex contains an unescaped /
    # Then extract the regex and whatever information comes after the /
    regexp = Regexp.new(scraping_rule[0..index])
    replacement = scraping_rule[index+2...scraping_rule.length]
    gsub = false
    gsub = true if replacement =~ /^\\/ # Indicates a rule that looks like this: '/(.*)(regex)(.*)/\2', one that will have partial data extracted from it later
                                        # If gsub is false it means that the rule is something more like '/regex/REPLACEMENT'
                                        # => where if the text matches the regex, the extracted data will simply be 'REPLACEMENT'
    rule = [regexp, replacement, gsub]
  else
    rule = [Regexp.new(scraping_rule)]
  end
end

def scrape(product_type, string_array)
# Uses the scraping rules to gather all data from the Amazon string array
  scraping_rules = get_scraping_rules(product_type)
  
  i = 0
  item_index = -1
  items = []
  while i < string_array.length
    text = string_array[i].gsub('&amp;', '&')
    
    if text =~ /asin = / || i == string_array.length-1 # If we've parsed a full item
      if item_index >= 0 # If at least one item has been parsed (we don't want to accidentally try to go to items[-1])
        # Make adjustments to the previous item
        
        items[item_index]['product_type'] = product_type
        # Fix formatting
        items[item_index]['screen_type'].upcase! if items[item_index]['screen_type'] && items[item_index]['screen_type'] !~ /plasma/i
        
        # Add default values where necessary
        items[item_index]['image_url_t'] = 'noimage' if items[item_index]['image_url_t'].nil?
        items[item_index]['image_url_s'] = 'noimage' if items[item_index]['image_url_s'].nil?
        items[item_index]['image_url_m'] = 'noimage' if items[item_index]['image_url_m'].nil?
        items[item_index]['image_url_l'] = 'noimage' if items[item_index]['image_url_l'].nil?
        items[item_index]['language'] = 'English' if product_type == 'movie_amazon' && items[item_index]['language'].nil?
        items[item_index]['app_type'] = 'software' if product_type == 'software_amazon' && items[item_index]['app_type'].nil?
        
        # Certain product types may have meaningless attributes; remove them
        if items[item_index]['title'] =~ /mount/i
          items[item_index].delete('size')
          items[item_index].delete('screen_type')
        end
      end
      if text =~ /asin = / # If there is still a product left
        items.push({})
        item_index += 1
      end
    end
    
    if item_index >= 0 # Only do this after an item has been parsed, don't want to access items[-1]
      # Run every rule on the text
      for rule in scraping_rules
        parent_rule = false
        parent_rule = true if rule.product_type == 'ADepartments'
        regex, replacement, gsub = get_real_rule(rule.regex)
        if text =~ Regexp.new(rule.remote_featurename) # If this text will contain the data the rule is looking for
          if gsub && text =~ regex # If certain data is going to be extracted
            items[item_index][rule.local_featurename] = text.gsub(regex, replacement) unless parent_rule && items[item_index][rule.local_featurename]
          elsif gsub && text.downcase =~ regex # If the above failed, we try downcasing the text because certain rules work for lower case
            items[item_index][rule.local_featurename] = text.downcase.gsub(regex, replacement) unless parent_rule && items[item_index][rule.local_featurename]
          elsif text.downcase =~ regex # If both of the above failed, just do a replacement
            items[item_index][rule.local_featurename] = replacement unless parent_rule && items[item_index][rule.local_featurename]
          end
        end
      end
    end
    
    i += 1
  end
  items
end

task :scrape_amazon_data => :environment do |t,args|
  require '/optemo/site/lib/helpers/sitespecific/amazon_scraper.rb'
  require '/optemo/firehose/app/models/scraping_rule.rb'
  require 'amazon/aws/search'
  include AmazonScraper
  
  search_params =   [
                      ['movie_amazon', 'Video', {'AudienceRating' => 'G'}],
                      ['movie_amazon', 'Video', {'AudienceRating' => 'PG'}],
                      ['movie_amazon', 'Video', {'AudienceRating' => 'PG-13'}],
                      ['movie_amazon', 'Video', {'AudienceRating' => 'R'}],
                      ['movie_amazon', 'Video', {'AudienceRating' => 'NC-17'}],
                      ['movie_amazon', 'Video', {'AudienceRating' => 'Unrated'}],
                      ['movie_amazon', 'Video', {'Title' => 'Lord of the Rings'}],
                      ['movie_amazon', 'Video', {'Title' => 'Star Wars'}],
                      ['movie_amazon', 'Video', {'Title' => 'Alien'}],
                      ['movie_amazon', 'Video', {'Title' => 'Harry Potter'}],
                      ['movie_amazon', 'Video', {'Title' => 'Indiana Jones'}],
                      ['movie_amazon', 'Video', {'Title' => 'King Kong'}],
                      ['movie_amazon', 'Video', {'Title' => 'Looney Toons'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'tv 1080p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'tv 720p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'ViewSonic', 'Keywords' => 'tv'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'tv 1080p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'tv 720p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Toshiba', 'Keywords' => 'tv 1080p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Toshiba', 'Keywords' => 'tv 720p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Coby', 'Keywords' => 'tv 1080p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Coby', 'Keywords' => 'tv 720p'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'LG', 'Keywords' => 'tv'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Sharp', 'Keywords' => 'tv'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'RCA', 'Keywords' => 'tv'}],
                      ['tv_amazon', 'Electronics', {'Manufacturer' => 'Vizio', 'Keywords' => 'tv'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Sony', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Samsung', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Canon', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Nikon', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'AgfaPhoto', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Panasonic', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Fuji', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Kodak', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Olympus', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Polaroid', 'Keywords' => 'camera'}],
                      ['camera_amazon', 'Electronics', {'Manufacturer' => 'Fotodiox', 'Keywords' => 'camera'}],
                      ['software_amazon', 'Software', {'Brand' => 'Microsoft', 'Keywords' => 'Software'}],
                      ['software_amazon', 'Software', {'Brand' => 'Microsoft', 'Keywords' => 'Game'}],
                      ['software_amazon', 'Software', {'Brand' => 'Apple', 'Keywords' => 'Software'}],
                      ['software_amazon', 'Software', {'Keywords' => 'photo'}],
                      ['software_amazon', 'Software', {'Brand' => 'Activision'}],
                      ['software_amazon', 'Software', {'Brand' => '2K'}],
                      ['software_amazon', 'Software', {'Brand' => 'Adobe'}],
                      ['software_amazon', 'Software', {'Brand' => 'Rosetta'}],
                      ['software_amazon', 'Software', {'Brand' => 'Encore'}],
                      ['software_amazon', 'Software', {'Brand' => 'Communications'}]
                    ]
                    
  items = []

  total_params = search_params.length
  completed = 0

  # Fill the items array with all search results
  for params in search_params
    puts "Downloading from Amazon: #{completed*100/total_params}%"
    (items << scrape(params[0], search_for(params[1], params[2]))).flatten!
    completed += 1
  end

  puts "Download complete: #{items.length} products returned"
  
  save(items)
end