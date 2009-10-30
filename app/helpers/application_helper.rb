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
  
  def condition_for_survey(sess)
    session[:user_id] % 10 == 0 && sess.actioncount > 5 && sess.offeredsurvey == false
    # We need the offeredsurvey field because some actions do not load layout or ajax and hence the survey can 
    # not always be offered at exactly a particular number of actions
  end
end
