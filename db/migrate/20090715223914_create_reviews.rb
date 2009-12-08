class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.string :product_type
      t.integer :product_id
      t.integer :rating
      t.integer :helpfulvotes
      t.datetime :date
      t.string :customerid
      t.integer :totalvotes
      t.text :content
      t.string :local_id
      t.string :source
      t.string :summary
      t.timestamps
    end
  end

  def self.down
    drop_table :reviews
  end
end
