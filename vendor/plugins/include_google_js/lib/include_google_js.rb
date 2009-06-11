module IncludeGoogleJs
  require 'ping'
  
  @@javascript_expansions = { :defaults => ActionView::Helpers::AssetTagHelper::JAVASCRIPT_DEFAULT_SOURCES.dup }
  @@include_google_js = false
  @@google_js_libs = %w[prototype scriptaculous jquery jqueryui mootools dojo yui swfobject]
  @@scriptaculous_files = ['controls','dragdrop','effects']
  @@default_google_js_libs = ['prototype','scriptaculous']
  @@google_js_to_include = []
  @@javascript_versions = Hash.new
  
  def self.included(base) 
    base.alias_method_chain :javascript_include_tag, :google_js
  end
  
  def javascript_include_tag_with_google_js(*sources)
    # split apart the sources, check for :cache, confirm that we're using :include_google_js, and grab :versions
    libraries               = sources.extract_options!.stringify_keys
    use_cache               = libraries.delete("cache")
    @@include_google_js     = libraries.delete("include_google_js") && IncludeGoogleJs.confirm_internet_connection
    @@javascript_versions   = libraries.delete("versions") || {}
    
    @@google_js_to_include  = []
    
    if ActionController::Base.perform_caching && use_cache # Using the locally cached libraries
      joined_javascript_name = (cache == true ? "all" : use_cache) + ".js"
      joined_javascript_path = File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, joined_javascript_name)

      write_asset_file_contents(joined_javascript_path, compute_javascript_paths(sources))
      javascript_src_tag(joined_javascript_name, libraries)
    else # Using Google libraries
      base_html = IncludeGoogleJs.expand_javascript_sources(sources).collect { |source| javascript_src_tag(source, libraries) }.join("\n")
      if @@include_google_js
        html = %Q{
          <script src='http://www.google.com/jsapi'></script>
          <script>
          }
        @@google_js_to_include.each do |js_lib|
          version = @@javascript_versions.has_key?(js_lib.split("-")[0].to_sym) ? @@javascript_versions.fetch(js_lib.split("-")[0].to_sym) : IncludeGoogleJs.get_file_version(js_lib)
          html += %Q{google.load("#{js_lib.split("-")[0]}", "#{version}");
          }
        end
        html += %Q{</script>
          #{base_html}
          }
      else
        html = base_html
      end
      return html
    end
  end

  def self.expand_javascript_sources(sources)
    if sources.include?(:all) # All libraries, get everything in the javascripts folder, see which are hosted by Google
      all_javascript_files = Dir[File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, '*.js')].collect { |file| File.basename(file).gsub(/\.\w+$/, '') }.sort
      all_javascript_files = IncludeGoogleJs.determine_if_google_hosts_files(all_javascript_files) if @@include_google_js
      @@all_javascript_sources ||= ((IncludeGoogleJs.determine_source(:defaults, @@javascript_expansions).dup & all_javascript_files) + all_javascript_files).uniq
    else
      defaults = sources.include?(:defaults)
      expanded_sources = []
      if defaults && @@include_google_js
        expanded_sources += IncludeGoogleJs.default_sources 
      else
        expanded_sources += sources.collect do |source|
          IncludeGoogleJs.determine_source(source, @@javascript_expansions)
        end.flatten
      end
      expanded_sources = IncludeGoogleJs.determine_if_google_hosts_files(expanded_sources) if @@include_google_js
      expanded_sources << "application" if File.exist?(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "application.js")) && defaults
      return expanded_sources
    end
  end
  
  def self.determine_if_google_hosts_files(javascript_files)
    @@google_js_to_include = []
    javascript_files.each do |file|
      if @@google_js_libs.include?(file.split("-")[0])
        @@google_js_to_include << file
      end
      if @@scriptaculous_files.include?(file)
        @@google_js_to_include << 'scriptaculous' unless @@google_js_to_include.include?('scriptaculous')
      end
    end
    # remove any files from the array if Google hosts it
    @@google_js_to_include.each do |file|
      javascript_files.delete(file)
    end
    # remove all of the scriptaculous files
    @@scriptaculous_files.each do |file|
      javascript_files.delete(file)
    end
    # Sort the Google files to make sure Prototype is loaded before Scriptaculous
    @@google_js_to_include.sort!
    return javascript_files
  end
  
  def self.default_sources
    sources = []
    sources += @@default_google_js_libs
    return sources
  end
  
  def self.confirm_internet_connection(url="ajax.googleapis.com")    
    Ping.pingecho(url,5,80) # --> true or false  
  end
  
  def self.get_file_version(file_name)
    version = "1"
    # split file_name for jquery
    file = file_name.split("-")[0]
    case file
      when "prototype"
        version = IncludeGoogleJs.parse_prototype
      when "scriptaculous"
        version = IncludeGoogleJs.parse_scriptaculous(file_name)
      when "jquery"
        version = IncludeGoogleJs.parse_jquery(file_name)
      when "jqueryui"
        version = IncludeGoogleJs.parse_jquery_ui(file_name)
      when "mootools"
        version = IncludeGoogleJs.parse_mootools(file_name)
      when "dojo"
        version = IncludeGoogleJs.parse_dojo(file_name)
      when "yui"
        version = IncludeGoogleJs.parse_yui(file_name)
      when "swfobject"
        version = IncludeGoogleJs.parse_swfobject(file_name)
      else
        version = "1"
    end
    return version
  end
  
  def self.determine_source(source, collection)
    case source
    when Symbol
      collection[source] || raise(ArgumentError, "No expansion found for #{source.inspect}")
    else
      source
    end
  end
  
  def self.parse_for_version(file="")
    if File.exist?(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")) # Check for the JS file
      case file.split("-")[0] # Split on '-' because of jQuery's file names with version numbers
        when "prototype"
          return IncludeGoogleJs.parse_prototype(file)
        when "scriptaculous"
          return IncludeGoogleJs.parse_scriptaculous(file)
        when "jquery"
          return IncludeGoogleJs.parse_jquery(file)
        when "jqueryui"
          return IncludeGoogleJs.parse_jquery_ui(file)
        when "mootools"
          return IncludeGoogleJs.parse_mootools(file)
        when "dojo"
          return IncludeGoogleJs.parse_dojo(file)
        when "yui"
          return IncludeGoogleJs.parse_yui(file)
        when "swfobject"
          return IncludeGoogleJs.parse_swfobject(file)
        else
          return 1
      end
    end
  end
  
  def self.parse_prototype(file="prototype")
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")).each do |line|
      return line.match(/[\d.]+/)[0] if line.include?("Version")
    end
  end
  
  def self.parse_scriptaculous(file="scriptaculous")
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")).each do |line|
      return line.match(/scriptaculous.js v([\d.]+)/i)[1]
    end
  end
  
  def self.parse_jquery(file="jquery")
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")).each do |line|
      version_array = line.scan(/jquery:\W?"([\d.]+)"/x).to_s
      return version_array.to_s unless version_array.blank?
    end
  end
  
  def self.parse_jquery_ui(file="jquery-ui")
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")).each do |line|
      version_array = line.scan(/version:\W?"([\d.]+)"/x).to_s
      return version_array.to_s unless version_array.blank?
    end
  end
  
  def self.parse_mootools(file="mootools")
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")).each do |line|
      return line.match(/version:["|']([\d\.]+)["|']/i)[1] if line.include?("version")
    end
  end
  
  def self.parse_dojo(file="dojo")
    version = nil
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "#{file}.js")).each do |line|
      match = line.scan(/\b[major|minor|patch]{5,}:([\d]+)/i)
      if match.size > 0
        version = match.shift.to_s
        match.each do |x|
          version += "."+x.to_s
        end
        return version
      end
    end
  end
  
  def self.parse_yui(file="")
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "yui/build/yuiloader/yuiloader-min.js")).each do |line|
      return line.match(/^version: ([\d.]+)/i)[1] if line.match(/^version: ([\d.]+)/i)
    end
  end
  
  def self.parse_swfobject
    File.open(File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "swfobject/swfobject.js")).each do |line|
      return line.match(/SWFObject v([\d\.]+)/i)[1] if line.match(/SWFObject v([\d\.]+)/i)
    end
  end
  
end
