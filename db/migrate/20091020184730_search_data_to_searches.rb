class SearchDataToSearches < ActiveRecord::Migration
  def self.up
    remove_column :sessions, :searchpids
    remove_column :sessions, :searchterm
    add_column :searches, :searchpids, :text
    add_column :searches, :searchterm, :string
  end

  def self.down
    add_column :sessions, :searchpids, :text
    add_column :sessions, :searchterm, :string
    remove_column :searches, :searchpids
    remove_column :searches, :searchterm
  end
end
