class CreateKeywordSearches < ActiveRecord::Migration
  def self.up
    create_table :keyword_searches do |t|
      t.string :keyword
      t.integer :product_id
    end
    add_index :keyword_searches, :keyword
  end

  def self.down
    drop_table :keyword_searches
  end
end
