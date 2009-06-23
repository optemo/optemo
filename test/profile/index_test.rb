require File.dirname(__FILE__) + '/../profile_test_helper'

class IndexTest < Test::Unit::TestCase
  include RubyProf::Test

  #fixtures :my_fixture

  def setup
    @controller = IndexTest.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_get
    #get(:index)
    puts "Test method"
  end
end
