require 'i18n/backend/active_record'
require "i18n/backend/cache"

#We do a lot of number_with_precision or currency_with_precision calls
#These do a defaults lookup, unfortunately this is a hash which would result in a DB lookup everytime
#Hashes are looked up in all the backends and then merged together
#The following code prevents this behaviour and just returns the first instance that is found
module I18nOptimization
  def translate(locale, key, default_options = {})
    options = default_options.except(:default)
  
    backends.each do |backend|
      catch(:exception) do
        options = default_options if backend == backends.last
        translation = backend.translate(locale, key, options)
        if !translation.nil?
          return translation
        end
      end
    end
  
    throw(:exception, I18n::MissingTranslation.new(locale, key, options))
  end
end

if Rails.env.production?
  I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Cache)
  I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
end
simple_backend = I18n::Backend::Simple.new
db_backend = I18n::Backend::ActiveRecord.new
I18n.backend = I18n::Backend::Chain.new(simple_backend,db_backend)
I18n.backend.extend(I18nOptimization)
