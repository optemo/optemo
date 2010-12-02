# This rewrite is here solely for the purpose of Googlebot.
# The basic idea is that, without javascript, Google will crawl an AJAX website using the following format:
# http://servername/?_escaped_fragment_=?
# This works great except for the embedding case, where an apache proxy directive (or other server directive) delivers the necessary embedding content via SSI:
#
#  ------ from httpd.conf ------
#  ProxyRequests Off
#
#  <Proxy *>
#     Order deny,allow
#     Allow from all
#  </Proxy>
#
#  ProxyPass /proxy http://assets.optemo.com:3000 ttl=120 retry=0
#  -----------------------------
#
# In this case, the request appears to be from the embedding (retailer's) server, say, walmart.com, but the url_for function would not insert
# the correct URL without correction on this point. So, we have to manually 

module ActionView::Helpers::UrlHelper
  @@retailer_server = "192.168.5.107" # This has to be the retailer's host for googlebot. 
  @@embedded_optemo_server = "assets.optemo.com"

  # = Action View URL Helpers
  def url_for(options = {})
    options ||= {}
    url = case options
    when String
      options
    when Hash
      options = options.symbolize_keys
      if request.host[Regexp.new(@@retailer_server)] 
#        route = options[:use_route]
        options = options.merge!({:only_path => false})
#        debugger
#        options = options.merge!({:use_route => "proxy", :extra_data => route}) if route
      elsif (request.domain && request.domain(4)[Regexp.new(@@embedded_optemo_server)]) 
        options = options.merge!({:only_path => false}) # reverse merge host and port here as necessary
      else
        options = options.reverse_merge!(:only_path => options[:host].nil?)
      end
      super
    when :back
      controller.request.env["HTTP_REFERER"] || 'javascript:history.back()'
    else
      polymorphic_path(options)
    end
    url
  end
end
