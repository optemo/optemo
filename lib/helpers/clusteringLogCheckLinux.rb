module Clusteringlogchecklinux
  def cleanupInvalidDatabase product
    begin
     logName = "#{Rails.root}/log/clustering.log"
     sqlFileName = "#{Rails.root}/lib/helpers/fixClusters.sql"
     return unless File.exists?(logName)
     file = File.open(logName, 'r')
     while (line = file.gets)
        if line.include? "#{Time.now.year}-"     
          timeLine = line
          verLine = file.gets
          endLine = file.gets
          while(endLine and endLine.include?("layer"))
            endLine = file.gets   
          end  
        end    
     end 
     if endLine.nil? || endLine.chomp != "The end." 
      return unless verLine
      ver = verLine.gsub(/Version: /, '').chomp
      config   = Rails::Configuration.new
      db = config.database_configuration[Rails.env]["database"]
      usr = config.database_configuration[Rails.env]['username']
      pswd = config.database_configuration[Rails.env]['password']
      delQ = "DELETE FROM #{product}_clusters WHERE version= #{ver}; DELETE FROM #{product}_nodes WHERE version= #{ver};" 
      file2 = File.open(sqlFileName, 'w') 
      file2.puts delQ 
      file2.close
      testQ = "mysql #{db} -u #{usr} -p#{pswd} < "+sqlFileName  
      system(testQ)
      File.open('log/clustering_reverts.log', 'a') {|f| f.puts("[#{Time.now}] Reverted version #{ver} (#{product}s)") }
    end  
     rescue EOFError
          file.close
    end
  end
end