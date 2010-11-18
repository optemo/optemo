module ImageHelper
  include GC
  require 'RMagick'
  # The first size, small, is only used in the mobile layout.
  # The second size, medium-small, is used in the list (Direct) layout. 
  # The third size, group-by, is used in the list (Direct) layout.
  
  @@size_names = ['s','ms','gb','m','l'] 
  @@sizes = [[70,50],[64,64],[80,80],[140,100],[400,300]]
  
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
    return "/images/#{Session.current.product_type}/#{id}_#{sz}.jpg"
  end

  # Returns a set of db records where the picture hasn't been downloaded
  def picless_records
    no_pic = []
    Product.find_all_by_product_type(Session.current.product_type).each do |rec|
      no_pic << rec unless File.exist?(filename_from_id(rec.id,""))
    end
    return no_pic.uniq
  end
  
  # Downloads a pic from the given url into the given folder with an
  # optional filename specification (else it'll use the downloaded
  # file's name by default)  
  def download_image url, folder, fname=nil
    if url.nil? or url == ''
      puts "WARNING: null or empty URL value for #{fname}"
      return nil 
    end
    #return url if url.include?(folder)
    filename = fname || url.split('/').pop
    ret = "/#{folder}/#{filename}"
    begin
      readme = open(url.force_encoding('UTF-8'))
      writehere = open("public/#{folder}/#{filename}","w")
      writehere.write(readme.read)
      writehere.close
    rescue OpenURI::HTTPError => e
      puts "ERROR Problem downloading from #{url} into #{filename}"
      puts "#{e.class.name} #{e.message}"
      writehere.close
      File.delete(writehere)
      return nil
    rescue Exception => e # This should not be here. Exceptions are definitely to be caught by the rake framework, not us. ZAT
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
    return "public/system/#{Session.current.product_type}/#{id}#{connect}#{sz}.jpg"
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
      offset_x = offset_y = 0
      if pic.columns < size[0] # This means that the width of the resized pic is now too small, so we need an x offset for the "extent" call
        offset_x = (size[0] - pic.columns).to_f / 2
      elsif pic.rows < size[1] # Here, the height is too small for the given dimensions, so we need a y offset for the "extent" call
        offset_y = (size[1] - pic.rows).to_f / 2
      else # "trimmed" version of the pic matched exactly. Do nothing.
      end
      pic.background_color = "#FFF"
      pic = pic.extent(size[0], size[1], offset_x, offset_y)
      pic.write "#{filename}_#{@@size_names[index]}.jpg"
      scaled << "#{filename}_#{@@size_names[index]}.jpg" if pic
    end
    return scaled
  end
  
  # Records missing length 'n width for all pics which have an image url
  def record_missing_pic_stats 
    no_img_sizes = []
    @@size_names.each do |sz|
      no_img_sizes = no_img_sizes | Product.find( :all, :conditions => ["(image#{sz}height IS NULL OR image#{sz}width IS NULL) AND image#{sz}url IS NOT NULL"])
    end  
    
    record_pic_stats(no_img_sizes)
  end
  
  def record_pic_urls recordset
    activerecords_to_save = []
    recordset.each do |rec|
      @@size_names.each do |sz|    
        puts "#{ url_from_item_and_sz(rec.id, sz)}"
        parse_and_set_attribute("image#{sz}url", url_from_item_and_sz(rec.id, sz), rec)
      end
      activerecords_to_save.push(rec)
    end
    if recordset.first
      recordset.first.class.transaction do
        activerecords_to_save.each(&:save)
      end
    end
  end
  
  def record_pic_stats(recset)
    activerecords_to_save = []
    recset.each do |record|
      # rec = record
      # rec = Product.find_by_id_and_product_type(record, Session.current.product_type)
      @@size_names.each do |sz|
        if File.exist?(filename_from_id(record.id,sz))
          # There is no error checking at the moment. Catching an exception here seems like a big mistake for some reason.
          image = Magick::ImageList.new(filename_from_id(record.id, sz))
          image = image.first if image and image.class.to_s == 'Magick::ImageList'
          if image
            parse_and_set_attribute("img#{sz}url", url_from_item_and_sz(record.id, sz), record)
            parse_and_set_attribute("img#{sz}height", image.rows, record) if image.rows
            parse_and_set_attribute("img#{sz}width", image.columns, record) if image.columns
          end
        else
          #debugger
          # What is the point of doing any of this? NULL is the default in the database anyhow, yes?
          # parse_and_set_attribute("img#{sz}url", nil, record)
          # parse_and_set_attribute("img#{sz}height", nil, record)
          # parse_and_set_attribute("img#{sz}width", nil, record)
        end
      end
      image = nil
      record.save
    end
  end
  
  # Donwload pics for each id in the { id => url} hash
  def download_all_pictures id_and_url_hash
    failed = []
    id_and_url_hash.each do |id, url|
      begin
        # The url is now in array form.
        unless url.blank? or file_exists_for(id)
          while not url.empty?
            oldurl = url.shift
            newurl = download_image(oldurl, "system/#{Session.current.product_type}", "#{id}.jpg")
            if(newurl.nil?)
              failed << id 
              puts "Failed to download picture for #{id} from #{oldurl}"
            else
              puts "Downloaded #{oldurl} into #{newurl}."
              url.clear
            end
          end
          sleep(1) # This is probably not necessary... there were some socket errors without it though.
        end
      rescue Magick::ImageMagickError => ime
        error_string = "#{$0} #{$!} #{ime}"
        if(error_string || '').match(/No such file or directory/).nil?
          puts "ImageMagick Error in download_all_pictures"
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
      rescue OpenURI::HTTPError => e
        puts "404 ERROR: #{e.class.name} #{e.message}"
      rescue Exception => e
        puts "ERROR: #{e.class.name} #{e.message}"
        puts "Resizing #{id} failed"
        failed << id
      end
    end
    return failed
  end
end
