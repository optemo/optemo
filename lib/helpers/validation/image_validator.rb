module ImageValidator
  
  require 'helpers/image_helper'
  include ImageHelper
  
  def resized_pics_exist record
    ['s','m','l'].each do |sz|
      unless file_exists_for(record[id], sz)
        url = record["image#{sz}url"]
        file = url.gsub(/images/, 'public/system') if url
        return false unless file and File.exists?(file)
      end
    end
    true
  end
  
  def pic_dimensions_exist record
    ['s','m','l'].each do |sz|
      ['width', 'height'].each do |dim|
        att = "image#{sz}#{dim}"
        return false unless record[att]
      end
    end
    true
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
    true
  end
  
end
