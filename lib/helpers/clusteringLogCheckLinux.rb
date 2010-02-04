module Clusteringlogchecklinux
  def cleanupInvalidDatabase product
    begin
      logName = "#{RAILS_ROOT}/log/clustering.log"
      sqlFileName = "#{RAILS_ROOT}/lib/helpers/fixClusters.sql"
      file = File.open(logName, 'r')
        while (line = file.gets)
          if line.include? "#{Time.now.year}-"     
            timeLine = line
            verLine = file.gets
            file.gets
            file.gets 
            file.gets
            endLine = file.gets
            unless endLine.nil?
              if (endLine.include? "layer")
                endLine = file.gets   
              end
            end    
          end
        end  
     if endLine.nil? || endLine.chomp != "The end." 
      ver = verLine.gsub(/Version: /, '').chomp
      config   = Rails::Configuration.new
      db = config.database_configuration[RAILS_ENV]["database"]
      usr = 'maria' # 'optemo'
      pswd = 'drowssap' # 'tinydancer'
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