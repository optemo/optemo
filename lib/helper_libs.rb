# This file contains useful groupings of helper modules

module Constants
  require 'helpers/global_constants'
end

module DataLib
  require 'helpers/database_helper'
  require 'helpers/scraping_helper'
  require 'helpers/cleaning_helper'
  require 'helpers/compare_helper'
  require 'helpers/fillin_helper'
  
  
  require 'helpers/logging_helper'
  
  require 'helpers/conversion_helper'
  require 'helpers/global_constants'

  require 'helpers/numbers'
  
  include LoggingHelper
  include DatabaseHelper
  include ScrapingHelper
  include CleaningHelper
  include CompareHelper
  include ConversionHelper
  include Constants
end

# Use in conjunction with DataLib:
module CartridgeLib
  require 'helpers/cartridge_helper'
  include CartridgeHelper
end

module ImageLib
  require 'helpers/image_helper'
  require 'helpers/fillin_helper'
  require 'open-uri'
  require 'helpers/logging_helper'
  
  include LoggingHelper
  include ImageHelper
  include ScrapingHelper
  include DatabaseHelper
end

module ValidationLib
  require 'helpers/validation_helper'
  
  require 'helpers/logging_helper'
  
  include LoggingHelper
  include ValidationHelper
end