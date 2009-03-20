class Saved < ActiveRecord::Base
  belongs_to :session
  belongs_to :search
end
