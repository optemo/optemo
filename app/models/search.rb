class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
  
  def URL
    ret = []
    "i0".upto("i#{result_count-1}"){|i|ret<<send(i.intern)}
    ret.compact.join('/')
  end
end
