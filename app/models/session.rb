class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  
  def URL
    ret = []
    "i0".upto("i#{result_count-1}"){|i|ret<<send(i.intern)}
    ret.compact.join('/')
  end
end
