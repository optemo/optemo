
module ImageHelper
  
  require 'RMagick'
  
  @@size_names = ['s','m','l']
  @@sizes = [[70,50],[140,100],[400,300]]
  
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
  
  def url_from_item_and_sz id, sz
    return "/images/#{$imgfolder}/#{id}_#{sz}.JPEG"
  end
  
  def unresized_recs
    not_resized = []
    $model.all.each do |rec|
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
    return not_resized
  end
  
  def picless_recs
    no_pic = []
    $model.all.each do |rec|
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
  
  def statless_recs
    no_stats = []
    @@size_names.each do |sz|
      no_stats = no_stats | $model.find( :all, \
        :conditions => ["image#{sz}height IS NULL OR image#{sz}width IS NULL OR image#{sz}url IS NOT NULL"])
    end
    return no_stats
  end
    
  def download_img url, folder, fname=nil
    return nil if url.nil? or url.empty?
    return url if url.include?(folder)
    filename = fname || url.split('/').pop
    ret = "/#{folder}/#{filename}"
    begin
    f = open("/optemo/site/public/#{folder}/#{filename}","w").write(open(url).read)
    rescue OpenURI::HTTPError => e
      ret = nil
      puts "#{e.type} #{e.message}"
    end
    ret
  end
  
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
  
  def resize img
    filename = img.filename.gsub(/\..+$/,'')
    scaled = []
    trimmed = img.trim
    if trimmed.rows != img.rows or trimmed.columns != img.columns
      puts "Start with #{img.rows} by #{img.columns}, end with  #{trimmed.rows} by #{trimmed.columns}" 
    end
    @@sizes.each do |size|
      scaled << trimmed.resize_to_fit(size[0],size[1])
    end
    scaled.each_with_index do |pic, index|
      pic.write "#{filename}_#{@@size_names[index]}.#{img.format}"
    end  
    return scaled.collect
  end
  
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
  
  def resize_all ids

    failed = []
    ids.each do |id|
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
      end
    end
    
    return failed
  end
  
  
  #def download_img url, folder, fname=nil
  #  return nil if url.nil? or url.empty?
  #  return url if url.include?(folder)
  #  filename = fname || url.split('/').pop
  #  ret = "/#{folder}/#{filename}"
  #  begin
  #  f = open("/optemo/site/public/#{folder}/#{filename}","w").write(open(url).read)
  #  rescue OpenURI::HTTPError => e
  #    ret = nil
  #    puts "#{e.type} #{e.message}"
  #  end
  #  ret
  #end
  
end