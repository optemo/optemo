class AmazonGroup < ActiveRecord::Base
  named_scope :unprocessed, :conditions => { :processed => false }
  named_scope :leafs, :conditions => { :leaf => true }
  require 'scrubyt'
  #Create new groups with new filled in variables
  def selectNextVar
    #Find which variable needs to be filled in
    nextVar = findBlankVar
    
    if nextVar.blank?
      #All the variables are filled, so let's get product details
      #Mark node as leaf node
      unless anyUnspecified
        self.leaf = true
        self.scrapedAt = Time.now
        save!
        system "rake amazon_all_details GROUP=#{self.id} "
      end
    else
      #Find new brands
      #Check for valid URL
      if self.url.blank? 
        puts "Error: Amazon Group has no URL"
        Process.exit
      end
      link = "http://amazon.com" + self.url

      camera_data = Scrubyt::Extractor.define do
        fetch link 
         brand "/html/body/table/tr/td/table/tr/td/table/tr/td/table/tr", ({:generalize => false}) do
           my_category"/td/div[1]"
           range "/td/table/tr/td/table/tr/td/div/a" do
             range_item("/span[@class='refinementLink']")
             range_url("href", { :type => :attribute })
           end
         end
      end  
      
      h = camera_data.to_hash
      changed = false
      h.each do |item|
        @category = item[:my_category]
        if @category == nextVar
          changed = true
          @range = item[:range_item].split(',')
          @url = item[:range_url].split(',')
          if @range.length != @url.length
            puts "Error scraping URLs and Ranges: The Number of URLs and Ranges don't match"
            Process.exit
          end
          #Create new clones
          @range.each_index do |i|
            #Create new node based on this one
            c = self.clone
            #Set the URL to what was found by the extractor
            c.url = @url[i]
            #Set the current variable that was found
            accessor = varName(nextVar) + "="
            c.send accessor.intern, @range[i]
            #Since the current node has been processed, set the new one to unprocessed
            c.processed = false
            #puts "Adding "+i.brand
            #puts "With url: "+i.url
            c.save!
          end
        end
      end
      accessor = varName(nextVar) + "="
      if !changed
        send accessor.intern, "Not Specified"
        save!
        selectNextVar
      end
    end
  end
  
  #Find the next variable which needs to be filled
  def findBlankVar
    if self.brand.blank? then return "Brand"
    elsif self.megapixels_range.blank? then return "Megapixels"
    elsif self.opticalZoom_range.blank? then return "Optical Zoom"
    elsif self.displaySize_range.blank? then return "Display Size"
    elsif self.imageStabilization.blank? then return "Image Stabilization"
    elsif self.viewfinderType.blank? then return "Viewfinder Type"
    else return ""
    end
  end
  
  def anyUnspecified
    x = "Not Specified"
    megapixels_range == x || opticalZoom_range == x || displaySize_range == x || brand == x
  end
  def downcase_first(x)
      x.sub(/./){$&.downcase}
  end
  def compact(x)
      x.gsub(/ /){''}
  end
  def varName(x)
      y = x.sub(/Megapixels/){"megapixels_range"}
      y.sub!(/Optical Zoom/){"opticalZoom_range"}
      y.sub!(/Display Size/){"displaySize_range"}
      compact(downcase_first(y))
  end
end
