class Similar < ActiveRecord::Base
  belongs_to :session
  has_one :camera
end
