namespace :javascript do
  libraries = %w[prototype scriptaculous jquery jqueryui mootools dojo yui swfobject]
  namespace :get do
    require 'net/http'
    
    namespace :get do
      rule /^javascript:get/ do |t|
        Rake::Task['environment'].invoke
        root = t.name.gsub("javascript:get:","").split(/:/)
        library = root[0]

        if library == "all"
          exception = root[1] == "except" ? root[2] : nil
          libraries.each do |name|
            get_library(name) unless name == exception
          end
        else
          get_library(library)
        end
      end
    end
    
    def get_library(name="")
      puts "Getting #{name}"
      case name
        when "prototype"
          # Prototype - http://www.prototypejs.org/assets/2008/9/29/prototype-1.6.0.3.js
          Net::HTTP.start('www.prototypejs.org',80) do |http|
            File.open("#{RAILS_ROOT}/public/javascripts/prototype.js", 'w') {
                |f| f.write(http.get('/assets/2008/9/29/prototype-1.6.0.3.js').body)
              }
          end
        when "scriptaculous"
          # Scriptaculous - http://script.aculo.us/dist/scriptaculous-js-1.8.2.zip
          unzip_js_library("http://script.aculo.us/dist/scriptaculous-js-1.8.2.zip")
          Dir.chdir("#{RAILS_ROOT}/public/javascripts") do
            `mv scriptaculous-js-1.8.2/src/* ./`
            `rm -rf scriptaculous-js-1.8.2`
          end
        when "jquery"
          # jQuery - http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js
          Net::HTTP.start('jqueryjs.googlecode.com',80) do |http|
            File.open("#{RAILS_ROOT}/public/javascripts/jquery.js", 'w') {
                |f| f.write(http.get('/files/jquery-1.3.2.min.js').body)
              }
          end
        when "jqueryui"
          # jQueryUI - http://www.jqueryui.com/download/jquery-ui-1.7.2.custom.zip
          unzip_js_library("http://www.jqueryui.com/download/jquery-ui-1.7.2.custom.zip")
          Dir.chdir("#{RAILS_ROOT}/public/javascripts") do
            `mv js/jquery-1.3.2.min.js jquery.js`
            `mv js/jquery-ui-1.7.2.custom.min.js jquery-ui.js `
            `rm -rf js`
          end
        when "mootools"
          # mootools - http://mootools.net/download/get/mootools-1.2.2-core-yc.js
          Net::HTTP.start('mootools.net',80) do |http|
            File.open("#{RAILS_ROOT}/public/javascripts/mootools.js", 'w') {
                |f| f.write(http.get('/download/get/mootools-1.2.2-core-yc.js').body)
              }
          end
        when "dojo"
          # Dojo - http://download.dojotoolkit.org/release-1.3.1/dojo.js
          Net::HTTP.start('download.dojotoolkit.org',80) do |http|
            File.open("#{RAILS_ROOT}/public/javascripts/dojo.js", 'w') {
                |f| f.write(http.get('/release-1.3.1/dojo.js').body)
              }
          end
        when "yui"
          # YUI - http://yuilibrary.com/downloads/yui2/yui_2.7.0b.zip
          unzip_js_library("http://yuilibrary.com/downloads/yui2/yui_2.7.0b.zip")
        when "swfobject"
          # swfobject - http://swfobject.googlecode.com/files/swfobject_2_1.zip
          unzip_js_library("http://swfobject.googlecode.com/files/swfobject_2_1.zip")
        else
          puts "I don't know about #{name}, sorry! Please check for a newer version of include_google_js."
        end
    end
    
    def unzip_js_library(path="")
      path_parts = path.match(/http:\/\/([\w.]+)(\/[\w.\/-]+)/i)
      Dir.chdir("#{RAILS_ROOT}/public/javascripts") do
        Net::HTTP.start(path_parts[1]) do |http|
          zip = http.get(path_parts[2])
          open("lib.zip", 'w') {
            |f| f.write(zip.body)
          }
          `unzip lib.zip`
          `rm lib.zip`
        end
      end
    end
  end
  
  namespace :remove do
    rule /^javascript:remove/ do |t|
      Rake::Task['environment'].invoke
      root = t.name.gsub("javascript:remove:","").split(/:/)
      library = root[0]
      exception = root[1] == "except" ? root[2] : nil
      
      if library == "all"
        libraries.each do |name|
          remove_library(name) unless name == exception
        end
      else
        remove_library(library)
      end
    end
  end
  
  def remove_library(name="")
    case name
      when "yui"
        puts "Removing YUI from /public/javascripts/"
        Dir.chdir("#{RAILS_ROOT}/public/javascripts") { `rm -rf yui` }
      when "scriptaculous"
        puts "Removing Scriptaculous files from /public/javascripts/"
        %w[scriptaculous builder controls dragdrop effects slider sound unittest].each do |file|
          Dir.chdir("#{RAILS_ROOT}/public/javascripts") { `rm #{file}.js` }
        end
      when "swfobject"
        Dir.chdir("#{RAILS_ROOT}/public/javascripts") { `rm -rf swfobject` }
      else
        if File.exist?(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{name}.js"))
          puts "Removing #{name} from /public/javascripts/"
          File.delete("#{RAILS_ROOT}/public/javascripts/#{name}.js")
        end
      end
  end
end