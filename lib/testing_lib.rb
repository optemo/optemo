module NoJavaTestLib
  require 'webrat'
  require 'mechanize'
  #require 'webrat/mechanize'
  
  require 'testing/navigation_helpers'  
  require 'helper_libs'
  require 'testing/site_test_asserts'
  require 'testing/site_tests'
  #require 'testing/test_session'
  
  include ScrapingLib
  include SiteTest
  include SiteTestAsserts
  include LoggingLib
end

module JavaTestLib
  require 'webrat'
  require 'webrat/selenium'
  
  require 'testing/navigation_helpers'
  require 'helper_libs'
  require 'testing/site_test_asserts'
  require 'testing/site_tests'
  require 'testing/java_test_session'
  
  include SiteTest
  include ScrapingLib
  include SiteTestAsserts
  include LoggingLib
end