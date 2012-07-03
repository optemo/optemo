# Note: this is a single function because passing the arrays as parameters between functions increased the time from 5 minutes to about 45 when running the script for a 14-day range

task :extract_logs, [:log_path,:destination_directory,:start_date,:end_date] => :environment do |t, args|
  path = args.log_path
  directory = args.destination_directory
  start_date = Date.strptime(args.start_date, "%Y-%m-%d")
  end_date = Date.strptime(args.end_date, "%Y-%m-%d")
  
  departments = ['B20218', 'B29157', 'B20232', 'B20352', 'F1127', 'F23773', 'F1002', 'F1084', 'F32511', 'F23813', 'F1082', 'F23033', 'home']
  
  # Create hash of arrays for each department
  lines = {}
  for dept in departments
    lines[dept] = []
  end

  # Get total number of lines so we can track completion
  line_string = %x[wc -l #{path}]
  total_lines = line_string.gsub(/.*\s(\d+).*/, '\1').to_i
  completed = 0

  File.open(path, 'r') do |f|
    checking = true
    valid_date = false
    department = 0
    while line = f.gets
      # Show progress
      puts "#{completed*100/total_lines}%" if completed % (total_lines/100) == 0
    
      # Once we find a line that is a new request (it'll contain a department ID), change where we're storing the lines so that every line gets stored to the correct department in the hash
      # Also turn off checking so we don't waste time. Checking gets turned back on once we find a blank line, since the previous request is now over and we need to start checking what department is next
      if checking
        d_index = 0
        if line =~ /"\/"/
          d_index = departments.index('home')
        else
          # Find out which department
          while d_index < departments.length
            if line =~ Regexp.new(departments[d_index])
              date_regex = /.*at\s(\d{4}-\d{2}-\d{2}).*/
              if line =~ date_regex
                date = Date.strptime(line.gsub(date_regex, '\1'), "%Y-%m-%d")
                if date >= start_date && date <= end_date
                  valid_date = true
                else
                  valid_date = false
                end
              end
              break
            end
            d_index += 1
          end
        end
      
        # If the line didn't contain any department, it's part of the previous request
        unless d_index == departments.length 
          department = d_index
          checking = false
        end
      elsif line == "\n" # If line is blank, start checking again
        checking = true
      end
    
      # Store the line
      lines[departments[department]] << line if valid_date
      completed += 1
    end
  end
  
  # Create the folder and new log files
  %x[mkdir #{directory}]
  for department in departments
    puts "Creating file: #{directory}#{department}.log"
    path = "#{directory}#{department}.log"
    file = File.new(path, 'w')
    file.close
    File.open(path, 'w') do |f|
      for line in lines[department]
        f.puts line
      end
    end
  end
end