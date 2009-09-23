module LoggingHelper
  
  def log msg
    @logfile.puts "LOGGER      " + msg if @logfile
    $logfile.puts "LOGGER      " + msg if $logfile
  end

  def report_error msg
    announce "ERROR      " + msg
  end
  
  def announce msg
    log msg
    puts msg
  end
  
  # a special logging function for data validation
  def log_v str
    printme  = " INVALID DATA :" + str
    @logfile.puts printme if @logfile
    $logfile.puts printme if $logfile
    puts printme  
  end
  
  def snore(sec)
    puts "Sleeping for #{sec} seconds.."
    sleep sec
  end
  
end