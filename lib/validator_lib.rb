# This file contains useful groupings of validation modules

# The basic
module GeneralValidationLib
  require 'helpers/validation_helper'
  require 'validators/general_validator'
  include ValidationHelper
  include GeneralValidator
  require 'helpers/logging_helper'
  include LoggingHelper
end

# The add-ons :

# For printers
module PrinterValidationLib
  require 'validators/printer_validator'
  include PrinterValidator
end

# For cameras
module CameraValidationLib
  require 'validators/camera_validator'
  include CameraValidator
end