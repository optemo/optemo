# Call syntax:
# rake extract_logs[/Users/milocarbol/Desktop/production.log,/Users/milocarbol/Desktop] -> processes all departments
# rake extract_logs[/Users/milocarbol/Desktop/production.log,/Users/milocarbol/Desktop] departments=B20218,B29157,F1002,etc. -> processes only B20218, B29157, F1002, etc.

task :extract_logs, [:log_path, :directory] => :environment do |t, args|
  path = args.log_path
  directory = args.directory
  raise "File not found: #{path}" unless Pathname.new(path).exist?
  raise "Invalid target directory: #{directory}" unless File.directory?(directory)
  
  HOME = "home"
  ERRORS = "errors"
  
  departments = ['B20218', 'B29157', 'B20232', 'B20352', 'F1127', 'F23773', 'F1002', 'F1084', 'F32511', 'F23813', 'F1082', 'F23033', HOME, ERRORS]
  
  # Set a batch number. Once a request text block puts the number of stored lines over this number, write it to the file.
  max_lines_to_batch = 25000
  write_batch = {}
  
  if ENV.include?("departments")
    desired_departments = ENV["departments"].split(",")
  else
    desired_departments = departments
  end
  
  # Create log files and the batch hash
  for dept in desired_departments
    dept_path = "#{directory}/#{dept}.log"
    raise "#{dept_path} already exists"if Pathname.new(dept_path).exist?
    file = File.new(dept_path, 'w')
    file.close
    
    write_batch[dept] = []
  end
  
  # Get total number of lines so we can display a progress bar
  line_string = %x[wc -l #{path}]
  total_lines = line_string.gsub(/.*\s(\d+).*/, '\1').to_i
  completed = 0
  
  puts "Processing file: #{path}"
  
  File.open(path, 'r') do |f|
    checking = true
    department_index = 0
    while line = f.gets
      completed += 1
      next if line.include?("Compiled") # If these lines are printed before any GET requests, the log analyzer gem will fail.
                                        # They have no effect on the analyzer, so ignore them.
      # Show progress
      if completed % (total_lines/100) == 0
        i = 1
        bar = ""
        while i < 100
          symbol = " "
          symbol = "#" if i <= completed*100/total_lines
          bar << symbol
          i+=1
        end
        print "[#{bar}]\r"
      end
    
      # Once we find a line that is a new request (it'll contain a department ID), change the department index to point to the correct department
      # Stop checking each line to see if it matches a department. Start checking again once we hit a newline character.
      desired_department = false
      if checking
        d_index = 0
        if line.include?("\"/\"")
          d_index = departments.index(HOME)
        elsif line.include?("Error") || line.include?("failed")
          d_index = departments.index(ERRORS)
        else
          # Find out which department
          while d_index < departments.length
            if line.include?(departments[d_index])
              break # d_index now corresponds to the index of the department in the departments array
            end
            d_index += 1
          end
        end
      
        # If the line contained a department, change the index we're saving lines to. Otherwise keep saving to the same department.
        unless d_index == departments.length 
          department_index = d_index
          checking = false
        end
        
      elsif line == "\n" # If line is blank, we've finished a request block, so start checking for departments again
        checking = true
      end
      
      # Store the lines if they're for a department we want
      if desired_departments.include?(departments[department_index])
        write_batch[departments[department_index]] << line
        
        # If there are enough lines in the batch writing hash, save the lines. Otherwise wait until there are enough lines.
        if write_batch[departments[department_index]].length > max_lines_to_batch
          File.open("#{directory}/#{departments[department_index]}.log", "a") do |out|
            for l in write_batch[departments[department_index]]
              out.puts l
            end
          end
          write_batch[departments[department_index]] = []
        end
      end
    end
  end
  
  # Save the rest of the batches that didn't reach the line limit before the file ended.
  write_batch.each do |department, lines|
    if lines.length > 0
      File.open("#{directory}/#{department}.log", "a") do |out|
        for l in lines
          out.puts l
        end
      end
    end
  end
  
  print "\n"
end