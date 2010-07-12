module ImageHelper
  
  include GC
  
  require 'RMagick'
  
  @@size_names = ['s','m','l']
  @@sizes = [[70,50],[140,100],[400,300]]
  
  # Is there a file for a product with this id and this size?
  def file_exists_for id, sz=''
    begin
      image = Magick::ImageList.new(filename_from_id(id,sz))
      image = image.first if image.class == Magick::ImageList
    rescue Magick::ImageMagickError => ime
      error_string = "#{$0} #{$!} #{ime}"
        if(error_string || '').match(/No such file or directory/).nil?
          puts "ImageMagick Error"
          puts error_string
        #else
          #puts "ImageMagick says: File not found for #{id}"
        end
    rescue Exception => e
      puts "#{e.class.name} #{e.message}"
    else
      if image and image.rows != 0
        GC.start
        return true 
      end
    end
    return nil
  end
  
  # Returns a relative URL for the file that should
  # theoretically be in place for this product
  def url_from_item_and_sz id, sz
    return nil if id.blank?
    return "/images/#{$product_type}/#{id}_#{sz}.jpg"
  end

  # Returns a set of db records where the picture hasn't been downloaded
  def picless_recs
    no_pic = []
    Product.all(:select => "id", :conditions => ["product_type=?", $product_type]).each do |rec|
      image = file_exists_for(rec.id)
      no_pic << rec.id unless image
    end
    return no_pic.uniq
  end
  
  # Downloads a pic from the given url into the given folder with an
  # optional filename specification (else it'll use the downloaded
  # file's name by default)  
  def download_img url, folder, fname=nil
    if url.nil? or url == ''
      puts "WARNING: null or empty URL value for #{fname}"
      return nil 
    end
    #return url if url.include?(folder)
    filename = fname || url.split('/').pop
    ret = "/#{folder}/#{filename}"
    begin
      readme = open(url)
      writehere = open("public/#{folder}/#{filename}","w")
      writehere.write(readme.read)
      writehere.close
    rescue OpenURI::HTTPError => e
      puts "ERROR Problem downloading from #{url} into #{filename}"
      puts "#{e.class.name} #{e.message}"
      return nil
    rescue Exception => e
      puts "ERROR Bug in code downloading from #{url} into #{filename}"
      puts "#{e.class.name} #{e.message}"
      return nil
    end
    ret
  end
  
  # Generates a systematic filename for a given picture ID
  # and a pre-set download folder
  def filename_from_id id, sz=''
    if sz==""
      connect=""
    else
     connect = "_" if sz!=''
    end
    return "public/system/#{$product_type}/#{id}#{connect}#{sz}.jpg"
  end
  
  # Resizes an image to the 3 pre-set sizes
  def resize img
    filename = img.filename.gsub(/\..+$/,'')
    scaled = []
    trimmed = img.trim
    trimmed.write "#{filename}_trimmed.jpg"
    if trimmed.rows != img.rows or trimmed.columns != img.columns
      puts "Start with #{img.rows} by #{img.columns}, end with  #{trimmed.rows} by #{trimmed.columns}" 
    end
    @@sizes.each_with_index do |size, index|
      pic = trimmed.resize_to_fit(size[0],size[1])
      pic.write "#{filename}_#{@@size_names[index]}.jpg"
      scaled << "#{filename}_#{@@size_names[index]}.jpg" if pic
    end
    return scaled
  end
  
  # Records missing length 'n width for all pics which have an image url
  def record_missing_pic_stats 
    no_img_sizes = []
    @@size_names.each do |sz|
      no_img_sizes = no_img_sizes | $product_type.find( :all, \
        :conditions => ["(image#{sz}height IS NULL OR image#{sz}width IS NULL) AND image#{sz}url IS NOT NULL"])
    end  
    
    record_pic_stats(no_img_sizes)
  end
  
  def record_pic_urls recordset
    recordset.each do |rec|
      @@size_names.each do |sz|    
        puts "#{ url_from_item_and_sz(rec.id, sz)}"
        fill_in("image#{sz}url", url_from_item_and_sz(rec.id, sz), rec)
      end
    end
  end
  
  def record_pic_stats recset
    recset.each do |record|
      # rec = record
      # rec = Product.find(record, :conditions => ["product_type=#{$product_type}"])
      @@size_names.each do |sz|
        if file_exists_for(record.id, sz)
          begin
            image = Magick::ImageList.new(filename_from_id(record.id, sz))
            image = image.first if image and image.class.to_s == 'Magick::ImageList'
          rescue Exception => e
            puts "WARNING: Can't get dimensions for #{sz} size pic of product #{record.id}"
            puts "#{e.class.name} #{e.message}"
            image = nil
          end
          if image
            fill_in("img#{sz}url", url_from_item_and_sz(record.id, sz), record)
            fill_in("img#{sz}height", image.rows, record) if image.rows
            fill_in("img#{sz}width", image.columns, record) if image.columns
          end
        else
          #debugger
          fill_in_forced("img#{sz}url", nil, record)
          fill_in_forced("img#{sz}height", nil, record)
          fill_in_forced("img#{sz}width", nil, record)
        end
      end
    end
  end
  
  # Donwload pics for each id in the { id => url} hash
  def download_all_pix id_and_url_hash
    failed = []
    id_and_url_hash.each do | id, url|
      begin
        unless url.nil? or url.empty? or file_exists_for(id)
          oldurl = url
          newurl = download_img(oldurl, "system/#{$product_type}", "#{id}.jpg")
          if(newurl.nil?)
            failed << id 
            puts "Failed to download picture for #{id} from #{oldurl}"
          else
            puts "Downloaded #{oldurl} into #{newurl}."
          end
          sleep(1) # This is probably not necessary
        end
      rescue Magick::ImageMagickError => ime
        error_string = "#{$0} #{$!} #{ime}"
        if(error_string || '').match(/No such file or directory/).nil?
          puts "ImageMagick Error in download_all_pix"
          puts error_string
        else
          #puts "ImageMagick says: File not found for #{id}"
        end
        failed << id
      rescue Exception => e # We do not want this. Should be a specific rescue, otherwise you cannot break the task with Ctrl-C ZAT 
        puts "#{e.class.name} #{e.message}"
        puts "Downloading #{id} failed"
        failed << id
      end
    end
    return failed
  end
  
  # Resize pictures for products with the given ids/for the given filenames.
  def resize_all ids
    failed = []
    ids.uniq.each do |id|
      image = nil
      begin
        image = Magick::ImageList.new(filename_from_id id)
        image = image.first if(image and image.class == Magick::ImageList)
        filenames = resize(image)
        failed << id if(filenames.nil? or filenames.length != 3)
        puts "Resizing #{id} successful"
        GC.start
      rescue Magick::ImageMagickError => ime
        error_string = "#{$0} #{$!} #{ime}"
        if(error_string || '').match(/No such file or directory/).nil?
          puts "ImageMagick Error in resize_all"
          puts error_string
        else
          #puts "ImageMagick says: File not found for #{id}"
        end
        failed << id
        puts "Resizing #{id} failed"
      rescue Exception => e
        puts "ERROR: #{e.class.name} #{e.message}"
        puts "Resizing #{id} failed"
        failed << id
      end
    end
    return failed
  end
end
