module DataHelper
  require 'data/database_helper'
  require 'data/scraping_helper'
  require 'data/cleaning_helper'
  require 'data/fillin_helper'
  require 'data/conversion_helper'
  include DatabaseHelper
  include ScrapingHelper
  include CleaningHelper
  include ConversionHelper
end

module CartridgeLib
  require 'data/cartridge_helper'
  include CartridgeHelper
end
