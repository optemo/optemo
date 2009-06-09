require 'test_helper'

class PrinterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def test_myvalid
    printer = Printer.first
    result = printer.myvalid?
    assert result
  end

end
