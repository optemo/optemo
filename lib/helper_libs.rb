# This file contains useful groupings of helper modules

require 'open-uri'

require 'helpers/atthash'

require 'helpers/database/fill_in'
require 'helpers/database/integration'

require 'helpers/database/tablespecific/offerings'
require 'helpers/database/tablespecific/products'
require 'helpers/database/tablespecific/reviews'
require 'helpers/database/tablespecific/scraped_products'

require 'helpers/global_constants'

require 'helpers/image_helper'

require 'helpers/scraping'

require 'helpers/logging'

require 'helpers/parsing/booleans'
require 'helpers/parsing/dimensions'
require 'helpers/parsing/enums'
require 'helpers/parsing/idfields'
require 'helpers/parsing/numbers'
require 'helpers/parsing/prices'
require 'helpers/parsing/strings'
require 'helpers/parsing/time'

require 'helpers/productspecific/anyproduct'
require 'helpers/productspecific/cameras'
#require 'helpers/productspecific/cartridges'
require 'helpers/productspecific/printers'

require 'helpers/validation/in_range_helper'


module ScrapingLib
  include ScrapingHelper
end

module DatabaseLib
  include FillInHelper
  include IntegrationHelper
  
  include OfferingsHelper
  include ProductsHelper
  include ScrapedProductsHelper
  include ReviewsHelper
end

# Use with parsing lib
module CleaningLib
  include AtthashHelper

  include CleaningHelper
  include CameraHelper
  include PrinterHelper
  #include CartridgeHelper
  
  include InRangeHelper
end

module ParsingLib
  include BooleanHelper
  include DimensionsHelper
  include EnumParser
  include FillInHelper
  include IdFieldsHelper
  include NumbersCleaner
  include PricesCleaner
  include StringCleaner
  include TimeParser
end

module LoggingLib
  include LoggingHelper  
end

module FillInLib
  include FillInHelper
  include NumbersCleaner
  include StringCleaner
end

module ImageLib
  include FillInLib
  include LoggingLib
  include ScrapingLib
  include ImageHelper
end

