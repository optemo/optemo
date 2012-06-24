# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def self.cache_lookup(key)
    # unless Rails.env.development? || Rails.env.test?
    if Rails.cache.class != ActiveSupport::Cache::FileStore # We have memcache loaded
      #Keys should not be longer than 250 chars
      key = Digest::MD5.hexdigest(key) if key.length > 250
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end
  def self.delete(key)
    if Rails.cache.class != ActiveSupport::Cache::FileStore # We have memcache loaded
      Rails.cache.delete(key) 
    end
  end
end
