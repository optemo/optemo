# This file contains useful groupings of helper modules

module Constants
  require 'helpers/global_constants'
end

module ScrapingLib
  require 'helpers/scraping'
  include ScrapingHelper
end

module LoggingLib
  require 'helpers/logging'
  include LoggingHelper  
end

module FillInLib
  require 'helpers/database/fill_in'
  include FillInHelper
end

module ImageLib
  require 'helpers/image_helper'
  require 'open-uri'
  
  include FillInLib
  include LoggingLib
  include ScrapingLib
  include ImageHelper
end

#########---- TODO
## The basic
#module GeneralValidationLib
#  require 'helpers/validation_helper'
#  require 'validators/general_validator'
#  include ValidationHelper
#  include GeneralValidator
#  include LoggingLib
#end
#
## The add-ons :
#
## For printers
#module PrinterValidationLib
#  require 'validators/printer_validator'
#  include PrinterValidator
#end
#
## For cameras
#module CameraValidationLib
#  require 'validators/camera_validator'
#  include CameraValidator
#end
#
## ---- BELOW THIS LINE: redo them.
#
#module DataLib
#  require 'helpers/database_helper'
#  require 'helpers/scraping_helper'
#  require 'helpers/cleaning_helper'
#  require 'helpers/compare_helper'
#  require 'helpers/fillin_helper'
#  
#  
#  require 'helpers/logging_helper'
#  
#  require 'helpers/conversion_helper'
#  require 'helpers/global_constants'
#
#  require 'helpers/numbers'
#  
#  include LoggingHelper
#  include DatabaseHelper
#  include ScrapingHelper
#  include CleaningHelper
#  include CompareHelper
#  include ConversionHelper
#  include Constants
#end
#
## Use in conjunction with DataLib:
#module CartridgeLib
#  require 'helpers/cartridge_helper'
#  include CartridgeHelper
#end