require 'i18n/backend/active_record'
require "i18n/backend/cache"
if Rails.env.production?
  I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Cache)
  I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
end
simple_backend = I18n::Backend::Simple.new
db_backend = I18n::Backend::ActiveRecord.new
I18n.backend = I18n::Backend::Chain.new(simple_backend,db_backend)