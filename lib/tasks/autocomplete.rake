namespace :autocomplete do
  desc "Fetch search terms for javascript-based autocomplete..."
  task :fetch => :environment do
    js_file = File.open("./public/javascripts/autocomplete_terms.js", "w")
    if (js_file)
      js_file.syswrite("/* Machine-generated javascript. Run \"rake autocomplete:fetch\" to regenerate. */\n")
    
      printer_terms = fetch_terms("Printer")
      camera_terms = fetch_terms("Camera")
      js_file.syswrite(printer_terms)
      js_file.syswrite("\n")
      js_file.syswrite(camera_terms)
      js_file.syswrite("\n")
      js_file.close
    else
      desc "Unable to open javascript file. Permissions issue?"
    end
  end
end

def fetch_terms(itemtype)
  model = itemtype.constantize
  # Must do a join followed by a split since the initial mapping of titles is like this: ["keywords are here", "and also here", ...]
  # The gsub lines are to take out the parentheses on both sides, take out commas, and take out trailing slashes.
  searchterms = model.find(:all, :select => "title").map{|c|c.title}.join(" ").split(" ").map{|t| t.gsub("()", '').gsub(/,/,' ').gsub(/\/$/,'').chomp}.uniq
  # Sanitize RSS-fed UTF-8 character input.
  ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
  searchterms = searchterms.map {|t| ic.iconv(t << ' ')[0..-2]}
  # Delete all the 1200x1200dpi, the "/" or "&" strings, all two-letter strings, and things that don't start with a letter or number.
  searchterms.delete_if {|t| t == '' || t.match('[0-9]+.[0-9]+') || t.match('^..?$') || t.match('^[^A-Za-z0-9]') || t.downcase.match('^print') || t.match('<.+>')}
  # The regular expression replacement to \\\\\' is intentional, believe it or not.
  return itemtype.downcase + '_searchterms = [\'' + searchterms.map{|t|(t.match(/[^A-Za-z0-9]$/)? t.chop.downcase : t.downcase).gsub("'","\\\\\'") }.uniq.join('\',\'') + '\'];'
  # Particular to this data
end
