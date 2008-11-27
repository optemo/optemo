class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :similars
end
