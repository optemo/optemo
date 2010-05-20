# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def self.cache_lookup(key)
    unless Rails.env.development?
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end
  
  def self.cache_lookup_zipped(key)
    require 'zlib'
    unless Rails.env.development?
      data = Rails.cache.read(key)
      if data.nil?
        data = yield
        Rails.cache.write(key,self.deflate(data))
      else
        data = self.inflate(data)
      end
      data
    else
      yield
    end
  end
  
  def self.inflate(string)
      zstream = Zlib::Inflate.new
      buf = zstream.inflate(string)
      zstream.finish
      zstream.close
      buf
      YAML::load(buf)
  end
  
  def self.deflate(data)
    string = data.to_yaml
    z = Zlib::Deflate.new
    dst = z.deflate(string, Zlib::FINISH)
    z.close
    dst
  end
end
