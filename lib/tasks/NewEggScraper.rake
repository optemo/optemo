require 'rubygems'
require 'scrubyt'

desc "Scraping NewEgg"
task :scrape_newegg => :environment do
  link ='http://www.newegg.com/Product/ProductList.aspx?Submit=ENE&N=2010270630&page=1&bop=And&Pagesize=20'
  product_data = Scrubyt::Extractor.define do
     fetch link 
     product do
       my_url '.midCol h3'
       myfeature 'Dimensions: 17.6" x 21.5" x 20.5"'
     end
  end
  puts product_data.to_xml
end
