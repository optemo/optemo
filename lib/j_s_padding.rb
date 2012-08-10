class JSPadding

  def initialize(app, options = {})
    @app = app
    @callback_param = options[:callback_param] || 'callback'
  end

  # Proxies the request to the application, stripping out the JSON-P callback
  # method and padding the response with the appropriate callback format.
  # 
  # Changes nothing if no <tt>callback</tt> param is specified.
  # 
  def call(env)
    # remove the callback and _ parameters BEFORE calling the backend, 
    # so that caching middleware does not store a copy for each value of the callback parameter
    request = Rack::Request.new(env)
    callback = request.params.delete(@callback_param)
    env['QUERY_STRING'] = env['QUERY_STRING'].split("&").delete_if{|param| param =~ /^(_|#{@callback_param})/}.join("&")
    
    status, headers, response = @app.call(env)
    if callback
      response = pad(callback, response)
      headers['Content-Length'] = response.first.bytesize.to_s
      headers['Content-Type'] = 'application/javascript;charset=utf-8'
    end
    [status, headers, response]
  end

  # Pads the response with the appropriate callback format according to the
  # JSON-P spec/requirements.
  # 
  # The Rack response spec indicates that it should be enumerable. The method
  # of combining all of the data into a single string makes sense since JSON
  # is returned as a full string.
  # 
  def pad(callback, response, body = "")
    # response.each{ |s| body << s.to_s.tr('\'','"').gsub("\n","\\\n") }
    # We use this odd form of gsub because we need to be able to replace single quotes for French. It's hard.
    # See here for more details if you want: http://notetoself.vrensk.com/2008/08/escaping-single-quotes-in-ruby-harder-than-expected/
    response.each{ |s| body << s.to_s.gsub(/\\|'/) {|c| "\\#{c}" }.tr("\r",'').gsub("\n","\\\n") }
    ["#{callback}('#{body}')"]
  end

end
