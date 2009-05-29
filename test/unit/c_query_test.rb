require 'test_helper'

class CQueryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "Checking Ultrasphinx search" do
    #Should find a brother printer
    #c = CQuery.new("printer",[186,187,182,185,183,180,181,184,179],Session.first,"Brother")
    #c = CQuery.new('Printer')
    #s = CQuery.send(:searchSphinx, "Brother")
    #assert !s.results.empty?
  end
end
