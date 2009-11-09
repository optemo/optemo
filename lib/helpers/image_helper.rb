module ImageHelper
  
  # -- Global vars to set --#
  # $model : eg Cartridge, Printer, Camera (the object not the string)
  # $id_field : the db field which is unique for every object that has 
  # the same picture (can just be ID)
  # $imgfolder : the subfolder where your pictures for the given product
  # type will go.
  
  require 'RMagick'
  
  @@size_names = ['s','m','l']
  @@sizes = [[70,50],[140,100],[400,300]]
  
  # Is there a file for a product with this id and this size?
  def file_exists_for id, sz=''
     begin
        image = Magick::ImageList.new(filename_from_id(id,sz))
        image = image.first if image.class == Magick::ImageList
        return false if image.nil?
     rescue
        return false
     else
        return image.rows
     end
     return false
  end
  
  # Returns a relative URL for the file that should
  # theoretically be in place for this product
  def url_from_item_and_sz id, sz
    return nil if id.nil? or id==''
    return "/images/#{$imgfolder}/#{id}_#{sz}.JPEG"
  end
  
  # Returns a set of db records where the pic hasn't been resized
  def unresized_recs model=$model
    not_resized = []
    model.all.each do |rec|
      image = nil
      @@size_names.each do |sz|        
        begin
          image = Magick::ImageList.new(filename_from_id(rec.[]($id_field), sz))
          image = image.first if image.class == Magick::ImageList
        rescue
          image = nil
        end
        not_resized << rec unless image
      end
    end
    return not_resized.uniq
  end
  
  # Returns a set of db records where the picture hasn't been downloaded
  def picless_recs model=$model
    no_pic = []
    model.all.each do |rec|
      image = nil
      begin
        image = Magick::ImageList.new(filename_from_id(rec.[]($id_field)))
        image = image.first if image.class == Magick::ImageList
      rescue
        image = nil
      end
        no_pic << rec unless image
    end
    return no_pic
  end
  
  # Returns a set of db records which have no pic length/width/url
  def statless_recs model=$model
    no_stats = []
    @@size_names.each do |sz|
      no_stats = no_stats | $model.find( :all, \
        :conditions => ["image#{sz}height IS NULL OR image#{sz}width IS NULL OR image#{sz}url IS NOT NULL"])
    end
    return no_stats
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
    rescue OpenURI::HTTPError => e
      puts "ERROR Problem downloading from #{url} into #{filename}"
      puts "#{e.type} #{e.message}"
      return nil
    rescue Exception => e
      puts "ERROR Bug in code downloading from #{url} into #{filename}"
      puts "#{e.type} #{e.message}"
      return nil
    end
    ret
  end
  
  # Generates a systematic filename for a given picture ID
  # and a pre-set download folder
  def filename_from_id id, sz=''
    if sz==""
      ext = 'jpg'
      connect=""
    else
      ext = 'JPEG'
      connect = "_" if sz!=''
    end
    return "public/system/#{$imgfolder}/#{id}#{connect}#{sz}.#{ext}"
  end
  
  # Resizes an image to the 3 pre-set sizes
  def resize img
    filename = img.filename.gsub(/\..+$/,'')
    scaled = []
    trimmed = img.trim
    trimmed.write "#{filename}_trimmed.#{img.format}"
    if trimmed.rows != img.rows or trimmed.columns != img.columns
      puts "Start with #{img.rows} by #{img.columns}, end with  #{trimmed.rows} by #{trimmed.columns}" 
    end
    @@sizes.each_with_index do |size, index|
      pic = trimmed.resize_to_fit(size[0],size[1])
      pic.write "#{filename}_#{@@size_names[index]}.#{img.format}"
      scaled << pic
    end  
    return scaled
  end
  
  # Records missing length 'n width for all pics which have an image url
  def record_missing_pic_stats 
    no_img_sizes = []
    @@size_names.each do |sz|
      no_img_sizes = no_img_sizes | $model.find( :all, \
        :conditions => ["(image#{sz}height IS NULL OR image#{sz}width IS NULL) AND image#{sz}url IS NOT NULL"])
    end  
    
    record_pic_stats no_img_sizes
  end
  
  def record_pic_urls recordset
    recordset.each do |rec|
      @@size_names.each do |sz|        
        #if rec.[]( "image#{sz}url" ).nil?
          fill_in "image#{sz}url", url_from_item_and_sz(rec.skuid, sz), rec
        #end
      end
    end
  end
  
  def record_pic_stats recset
    recset.each do |rec|
      image = nil
      @@size_names.each do |sz|        
        begin
          image = Magick::ImageList.new(filename_from_id(rec.[]($id_field), sz))
          image = image.first if image.class == Magick::ImageList
        rescue
          puts "WARNING: Can't get dimensions for #{sz} size pic of product #{rec.[]($id_field)}"
          image = nil
        end
        if image
          fill_in "image#{sz}url", url_from_item_and_sz(rec.[]($id_field), sz), rec
          fill_in "image#{sz}height", image.rows, rec if image.rows
          fill_in "image#{sz}width", image.columns, rec if image.columns
        end
      end
    end
  end
  
  # Download pics for each item in the set of db records
  def download_these recordset
    failed = []
    
    recordset.each do |x|
      id = x.[]($id_field)
      url = x.[]($img_url_field)
      unless url.nil? or url.empty? or file_exists_for(id)
        oldurl = url
        newurl = download_img oldurl, "system/#{$imgfolder}", "#{id}.jpg"
        
        failed << id if(newurl.nil?)
        
        puts " Waiting waiting. Downloaded #{oldurl} into #{newurl}."
        sleep(30)
      end
    end
    
    return failed
  end
  
  # Donwload pics for each id in the { id => url} hash
  def download_all_pix id_and_url_hash
    failed = []
    
    id_and_url_hash.each do | id, url|
      unless url.nil? or url.empty? or file_exists_for(id)
        oldurl = url
        newurl = download_img oldurl, "system/#{$imgfolder}", "#{id}.jpg"
        
        failed << id if(newurl.nil?)
        
        puts " Waiting waiting. Downloaded #{oldurl} into #{newurl}."
        sleep(30)
      end
    end
    
    return failed
  end
  
  # Resize pictures for products with the given ids/for the given filenames.
  def resize_all ids

    failed = []
    ids.uniq.each do |id|
      begin
        image = Magick::ImageList.new(filename_from_id id)
        image = image.first if image.class == Magick::ImageList
        filenames = resize image
        failed << id if filenames.length == 0
        # TODO
        #@@size_names.each do |sz|
        #    fill_in "image#{sz}url", url_from_item_and_sz(id, sz), rec
        #end
      rescue
        image = nil
        failed << id
        puts "Resizing #{id} failed"
      end
    end
    
    return failed
  end
  
end