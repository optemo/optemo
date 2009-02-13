class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :camera
  has_many :vieweds
  
  def URL
    ret = []
    "i0".upto("i#{result_count}"){|i|out<<i}
    ret.compact.join('/')
  end
end
