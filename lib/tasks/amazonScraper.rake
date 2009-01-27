#require 'rubygems'
#require 'scrubyt'

desc "Scraping Amazon"
task :scrape_amazon => :environment do
    extractor = Scrubyt::Extractor.define do
    fetch 'http://www.amazon.com/s/qid=1221217879/ref=sr_nr_n_0?ie=UTF8&rs=281052&bbn=330405011&rnid=281052&rh=n%3A502394%2Cn%3A281052%2Cn%3A330405011'
   # click_link brand 
  
    
    
    
        camera("/html/body/table/tr/td/div/form/table/tr/td/table/tr/td/table/tr/td/table", { :generalize => true }) do
         camera_title("/tr[2]/td[1]/div[1]/a[1]/", {:write_text => true}) do
           camera_link "//a" do
             url_detail do 
              # techDetail_link 'See more technical details' do 
                 cameraTechInfo("/html/body/div/div/ul", { :generalize => true }) do
                   pixel("/li[1]")
                   zoom("/li[2]")
                   disp("/li[3]") 
                 end
              #end
            end
          end
        end
      end    
      #next_page "Next", :limit => 2                    
    end
    
    #saving the data to mysql, requires the environment line above

    flash[:notice] = extractor.to_xml
    product_data_hash = extractor.to_hash
    product_data_hash.each do |item|
      @product = Camera.create(item)
      @product.save
    end
end
 