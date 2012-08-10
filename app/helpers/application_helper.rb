# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def url_for_intl(region)
    case region
    when "com"
      request.url.gsub(".ca",".com")
    when "ca"
      request.url.gsub(".com",".ca")
    else
      request.url
    end
  end
  
  def fr?
    I18n.locale == :fr ? "_fr" : ""
  end

  def isfr?
    I18n.locale == :fr
  end 
  
  def utfstr(s)
    if RUBY_VERSION == "1.9.1"
      s.force_encoding("UTF-8")
    else
      s
    end
  end
end
