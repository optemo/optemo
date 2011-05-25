# The purpose of this is to disable etags when processing requests from Internet Explorer
# This is because IE requires a P3P header in order to accept cookies within an iframe
# and if etags are used then subsequent calls for the same page are met with a 304 not changed
# response, which is not allowed (by W3C) to contain P3P headers.  Apache strips them even if we
# patch Rails to set them anyway

# see refs:
# http://robanderson123.wordpress.com/2011/02/25/p3p-header-hell/
# Apache filters P3P headers from 304 responses: http://groups.google.com/group/rack-devel/browse_thread/thread/11da5971522b107b
# general explanation of the problem: http://tempe.st/tag/ruby-on-rails/

module ActionDispatch

  class Request

    alias_method :etag_matches_original?, :etag_matches?

    def etag_matches?(etag)
      !env['HTTP_USER_AGENT'].include?('MSIE') && etag_matches_original?(etag)
    end

  end

  class Response

    alias_method :etag_original?, :etag?

    def etag?
      request.env['HTTP_USER_AGENT'].include?('MSIE') || etag_original?
    end

  end
end