class AddSeesimToSearches < ActiveRecord::Migration
  def self.up
    add_column :searches, :seesim, :string
  end

  def self.down
    remove_column :searches, :seesim
  end
end
