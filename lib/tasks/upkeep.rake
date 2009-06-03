#Here is where general upkeep scripts are

desc "Clear all user data"
task :clear_user do
  %w(20081127225900 20081127225930 20081127225953 20081208220610 20090428233856).each{|v|recreateTable(v)}
end

def recreateTable(version)
  ENV['VERSION']=version
  Rake::Task['db:migrate:down'].invoke
  Rake::Task['db:migrate:up'].invoke
end