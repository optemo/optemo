class Search < ActiveRecord::Base
  belongs_to :session
  belongs_to :cluster
  has_many :vieweds
end
