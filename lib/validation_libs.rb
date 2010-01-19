# This file contains useful groupings of helper modules

module ValidationLib
  require 'helpers/global_constants'
  require 'helpers/logging'
  
  require   'helpers/validation/camera_validator'
  require     'helpers/validation/data_validator'
  require    'helpers/validation/image_validator'
  require  'helpers/validation/printer_validator'
  include LoggingHelper
  include DataValidator
  include ImageValidator
end

