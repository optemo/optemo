class Viewed < ActiveRecord::Base
  belongs_to :session
  belongs_to :search
end
