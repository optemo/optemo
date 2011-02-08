# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def self.cache_lookup(key)
    # unless Rails.env.development? || Rails.env.test?
    if Rails.cache.class == ActiveSupport::Cache::MemCacheStore # We have memcache loaded
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end
end
