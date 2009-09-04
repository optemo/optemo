module NoJavaTestLib
  require 'webrat'
  require 'mechanize'
  require 'webrat/mechanize'
  
  require 'testing/site_nav_helpers'
  require 'testing/printer_helpers'
  
  require 'testing/test_session'
  
  require 'helpers/scraping_helper'
  include ScrapingHelper

  require 'testing/site_tests'
  include PrinterTest
  
  require 'testing/site_test_asserts'
  include PrinterTestAsserts
  
end

module JavaTestLib
  require 'webrat'
  require 'webrat/selenium'
  
  require 'testing/site_nav_helpers'
  require 'testing/printer_helpers'
  
  require 'testing/java_test_session'
  
  require 'helpers/scraping_helper'
  include ScrapingHelper

  require 'testing/site_tests'
  include PrinterTest
  
  require 'testing/site_test_asserts'
  include PrinterTestAsserts
  
  
end