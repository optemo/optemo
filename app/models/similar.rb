class Similar < ActiveRecord::Base
  belongs_to :session
  belongs_to :camera
end
