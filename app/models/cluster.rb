class Cluster < ActiveRecord::Base
  belongs_to :session
  has_many :nodes
end
