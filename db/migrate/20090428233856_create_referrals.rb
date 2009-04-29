class CreateReferrals < ActiveRecord::Migration
  def self.up
    create_table :referrals do |t|
      t.integer :product_id
      t.string :product_type
      t.integer :session_id
      t.integer :retailer_offering_id

      t.timestamps
    end
  end

  def self.down
    drop_table :referrals
  end
end
