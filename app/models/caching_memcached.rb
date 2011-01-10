# Be careful when selecting a hash key that you don't cache data with identical keys. This is the #1 source of caching bugs so far.
module CachingMemcached
  def self.cache_lookup(key)
    # There is another test that might work well, but it should be tested before being put into production
    # if Rails.cache.class == ActiveSupport::Cache::MemCacheStore # We have memcache loaded
    unless Rails.env.development? || Rails.env.test?
      Rails.cache.fetch(key) { yield }
    else
      yield
    end
  end
end
