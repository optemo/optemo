class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  
  def last_search
    s = searches.find(:last)
    s.URL if !s.nil?
  end
end
