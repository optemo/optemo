class Jsonify
  def initialize(app)
    @app = app # Put app state in a local instance variable
  end
  def call(env)
    status, headers, response = @app.call(env)
    if (status != 304 && headers["Content-Type"].include?("application/json") && !(response.blank?)) # middle condition tests if &format=json is in the URL
      doctored_response = response.body.gsub("\\\"","\\\\\"").gsub("\"","\\\"")
      doctored_response = doctored_response.gsub("<script>", "<src\" + \"ipt>").gsub("</script>", "</scr\" + \"ipt>").gsub("\n","\\n")
      
      [status, headers, "log_stuff({data: \"" + doctored_response + "\"});"] # This is weird, but it escapes the \" if it exists, and all the quotes into \"
    else
      [status, headers, response] # Don't do anything to normal requests.
    end
  end
end
