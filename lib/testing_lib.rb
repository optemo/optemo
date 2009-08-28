module NoJavaTestLib
  require 'webrat'
  require 'mechanize'
  require 'webrat/mechanize'
  
  require 'testing/printer_page_helpers'
  require 'testing/test_session'
  
  require 'helpers/scraping_helper'
  include ScrapingHelper

  require 'testing/printer_tests'
  include PrinterTest
  
  require 'testing/printer_test_asserts'
  include PrinterTestAsserts
  
end

module JavaTestLib
  require 'webrat'
  require 'webrat/selenium'
  require 'testing/printer_page_helpers'
  require 'testing/java_test_session'
  
  require 'helpers/scraping_helper'
  include ScrapingHelper

  require 'testing/printer_tests'
  include PrinterTest
  
  require 'testing/printer_test_asserts'
  include PrinterTestAsserts
end