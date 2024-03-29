namespace :autocomplete do
  desc "Fetch search terms for javascript-based autocomplete..."
  task :fetch => :environment do
    js_file = File.open("#{Rails.root}/public/javascripts/autocomplete_terms.js", File::WRONLY|File::TRUNC|File::CREAT)    
    if (js_file)
      js_file.syswrite("/* Machine-generated javascript. Run \"rake autocomplete:fetch\" to regenerate. */\n")
      yml_file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
      unless (yml_file.nil? || yml_file.empty?)
        product_types = {}
        yml_file.each do |p_yml_entry|
          product_types[p_yml_entry.second["product_type"]] = (p_yml_entry.first)
        end
        product_types.each do |pType_url_pair| # This is a pair like this: "camera_us"=>"m.browsethenbuy.com" - seems backwards, but makes the hash unique on product_type
          Session.new(pType_url_pair[1]) # The URL
          terms = fetch_terms(pType_url_pair[0]) # The product type
          js_file.syswrite(terms)
          js_file.syswrite("\n")
        end
        js_file.close
      else
        puts "Unable to open products.yml"
      end
    else
      puts "Unable to open javascript file. Permissions issue?"
    end
  end
end

def fetch_terms(product_type)
  # Must do a join followed by a split since the initial mapping of titles is like this: ["keywords are here", "and also here", ...]
  # The gsub lines are to take out the parentheses on both sides, take out commas, and take out trailing slashes.
  searchterms = Product.instock.map{|c|c.title}.join(" ").split(" ").map{|t| t.gsub("()", '').gsub(/,/,' ').gsub(/\/$/,'').chomp}.uniq
  # Sanitize RSS-fed UTF-8 character input.
  ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
  searchterms = searchterms.map {|t| ic.iconv(t << ' ')[0..-2]}
  # Delete all the 1200x1200dpi, the "/" or "&" strings, all two-letter strings, and things that don't start with a letter or number.
  searchterms.delete_if {|t| t == '' || t.match('[0-9]+.[0-9]+') || t.match('^..?$') || t.match('^[^A-Za-z0-9]') || t.downcase.match('^print') || t.match('<.+>')}
  useless_search_terms = ["a", "has", "such", "accordance", "have", "suitable", "according", "having", "than", "all", "herein", "that", "also", "however", "the", "an", "if", "their", "and", "in", "then", "another", "into", "there", "are", "invention", "thereby", "as", "is", "therefore", "at", "it", "thereof", "be", "its", "thereto", "because", "means", "these", "been", "not", "they", "being", "now", "this", "by", "of", "those", "claim", "on", "thus", "comprises", "onto", "to", "corresponding", "or", "use", "could", "other", "various", "described", "particularly", "was", "desired", "preferably", "were", "do", "preferred", "what", "does", "present", "when", "each", "provide", "where", "embodiment", "provided", "whereby", "fig", "provides", "wherein", "figs", "relatively", "which", "for", "respectively", "while", "from", "said", "who", "further", "should", "will", "generally", "since", "with", "had", "some", "would"]
  searchterms.delete_if {|t| useless_search_terms.index(t)}
  searchterms.delete_if {|t| Product.search_for_ids(:per_page => 10000, :star => true, :conditions => {:product_type => product_type, :title => t.downcase}).empty? }
  # The regular expression replacement to \\\\\' is intentional, believe it or not.
  return product_type.downcase + '_searchterms = [\'' + searchterms.map{|t|(t.match(/[^A-Za-z0-9]$/)? t.chop.downcase : t.downcase).gsub("'","\\\\\'") }.uniq.join('\',\'') + '\'];'
  # Particular to this data
end
