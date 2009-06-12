class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  
  def clearFilters
    Session.column_names.delete_if{|i| %w(id created_at updated_at ip parent_id).index(i)}.each do |name|
      send((name+'=').intern, Session.columns_hash[name].default)
    end
    save
  end
  
  def self.ip_uniques
    old = %w(192.168.5.1 216.241.231.100 75.157.187.83 72.30.79.84 207.216.69.84 24.86.24.240 70.79.157.173 204.244.194.35 93.158.144.28 24.83.243.193 174.6.20.7 66.249.68.38 38.105.86.201 216.34.209.23 75.101.227.178 142.58.249.155 142.58.240.33 206.186.74.5 66.249.68.58 96.53.217.238 66.249.68.105 97.74.127.171 130.83.142.31)
    (self.all.map{|s|s.ip}+old).uniq.delete_if{|i|i =~ /^(192\.168.|127.0.|::1)/}
  end
  
  def self.ip_total
    self.all.map{|s|s.ip}.delete_if{|i|i =~ /^(192\.168.|127.0.|::1)/}
  end
end
