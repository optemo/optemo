class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  
  def URL
    ret = []
    results = result_count < 9 ? result_count - 1 : 8
    "i0".upto("i#{results}"){|i|ret<<send(i.intern)}
    ret.compact.join('/')
  end
end
