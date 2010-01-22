# Helpful logging functions!
# Assumes that the log is called either 
# @logfile or $logfile
module LoggingHelper
  
  def log msg
    @logfile.puts "LOGGER      " + msg if @logfile and !@logfile.closed?
    $logfile.puts "LOGGER      " + msg if $logfile and !$logfile.closed?
  end
  
  def timed_log msg
    log(timed(msg))
  end

  def report_error msg
    announce "ERROR      " + msg
  end
  
  def announce msg
    log msg
    puts msg
  end
  
  def timed msg
    return "#{[Time.now]} " + msg
  end
  
  def timed_announce msg
    announce(timed(msg))
  end
  
  # a special logging function for data validation
  def log_v str
    printme  = " INVALID DATA :" + str
    announce printme
  end

  def log_snore(sec)
    log "Sleeping for #{sec} seconds.."
    sleep sec
  end
  
  def snore(sec)
    puts "Sleeping for #{sec} seconds.."
    sleep sec
  end
  
end