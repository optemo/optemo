class CreateGrabberOfferings < ActiveRecord::Migration
  def self.up
    create_table :grabber_offerings do |t|

      t.timestamps
      t.primary_key :id
      t.integer   :product_id
      t.integer   :offering_id
      t.string    :item_number
    end
  end

  def self.down
    drop_table :grabber_offerings
  end
end
