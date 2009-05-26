class CreateCQueries < ActiveRecord::Migration
  def self.up
    create_table :c_queries do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :c_queries
  end
end
