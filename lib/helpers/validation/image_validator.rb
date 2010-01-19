module ImageValidator
  
  def pic_exists record
    return true if file_exists_for(record[$id_field], '')
    return false
  end
  
  def resized_pics_exist record
    exists = true
    ['s','m','l'].each do |sz|
      unless file_exists_for(record[$id_field], sz)
        url = record["image#{sz}url"]
        file = url.gsub(/images/, 'public/system') if url
        unless file and File.exists?(file)
          exists = false 
        end
      end
    end
    return exists
  end
  
  def pic_dimensions_exist record
    ['s','m','l'].each do |sz|
      ['width', 'height'].each do |dim|
        att = "image#{sz}#{dim}"
        return false unless record[att]
      end
    end
    return true
  end
  
  def pic_urls_not_broken record
    ['s','m','l'].each do |sz|
       attrname = "image#{sz}url"
       url = record[attrname]
       if url
         file = url.gsub(/images/, 'public/system')
         if !File.exists?(".#{file}")
           return false
         end
       end
     end
     return true
  end
  
end