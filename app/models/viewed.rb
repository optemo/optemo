class Viewed < ActiveRecord::Base
  belongs_to :session
  has_one :camera
end
