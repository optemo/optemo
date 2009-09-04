module LoggingHelper
  
  def log msg
    @logfile.puts "LOGGER      " + msg if @logfile
    $logfile.puts "LOGGER      " + msg if $logfile
  end

  def report_error msg
    $logfile.puts "ERROR      " + msg if $logfile
    @logfile.puts "ERROR      " + msg if @logfile
    puts "ERROR: " + msg
  end
  
  # a special logging function for data validation
  def log_v str
    printme  = " INVALID DATA :" + str
    @logfile.puts printme if @logfile
    $logfile.puts printme if $logfile
    puts printme  
  end
  
end