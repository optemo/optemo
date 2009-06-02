class Session < ActiveRecord::Base
  has_many :saveds
  has_many :vieweds
  has_many :searches
  
  def clearFilters
    Session.column_names.delete_if{|i| %w(id created_at updated_at ip parent_id).index(i)}.each do |name|
      send((name+'=').intern, Session.columns_hash[name].default)
    end
  end
end
