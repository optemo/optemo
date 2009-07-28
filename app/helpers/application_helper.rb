# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def title
    h(@title_full ? @title_full : [@title_prefix, $SITE_TITLE].compact.join(' - '))
  end
  
  def describe
    h(@description ? @description : "LaserPrinterHub provides price comparisons and detailed information to help you find the right printer for you.")
  end
  
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
end
