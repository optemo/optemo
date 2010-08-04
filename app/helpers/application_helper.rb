# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def title
    h(@title_full ? @title_full : [@title_prefix, t("#{Session.current.product_type}.sitetitle")].compact.join(' - '))
  end
  
  def describe
    h(@description ? @description : t("#{Session.current.product_type}.defaultdesc"))
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
  
  def fr?
    I18n.locale == "fr" ? "_fr" : ""
  end
  
  def utfstr(s)
    if RUBY_VERSION == "1.9.1"
      s.force_encoding("UTF-8")
    else
      s
    end
  end
end
