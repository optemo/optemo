class AddAbTestingToUserTable < ActiveRecord::Migration
  def self.up
    add_column :users, :ab_testing_type, :integer, :default => 0
  end

  def self.down
    remove_column :users, :ab_testing_type
  end
end
