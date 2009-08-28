module NoJavaTestLib
  require 'webrat'
  require 'mechanize' # Needed to make Webrat work
  require 'testing/test_session'
  
  require 'helpers/scraping_helper'
  include ScrapingHelper
  
  require 'testing/printer_test_mod'
  include PrinterTest
  
  require 'testing/printer_test_asserts'
  include PrinterTestAsserts
end

module JavaTestLib
  require 'webrat'
  require 'webrat/selenium'
  require 'testing/java_test_session'
  
  require 'helpers/scraping_helper'
  include ScrapingHelper

  require 'testing/printer_test_mod'
  include PrinterTest
  
  require 'testing/printer_test_asserts'
  include PrinterTestAsserts
end