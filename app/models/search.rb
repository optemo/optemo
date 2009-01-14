class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :camera
  has_many :vieweds
  
  def URL
    [i0, i1, i2, i3, i4, i5, i6, i7, i8].join('/')
  end
end
