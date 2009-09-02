class CreateGrabberCartridges < ActiveRecord::Migration
  def self.up
    create_table :grabber_cartridges do |t|

      t.timestamps
      t.primary_key :id
      
      t.string    :item_number
      t.text      :detailpageurl
      t.text      :image
      t.string    :pricestr
      t.string    :title
      t.string    :availability
      t.string    :printermodel
      t.string    :printerbrand
      t.integer   :printerid
      t.string    :printerids
    end
  end

  def self.down
    drop_table :grabber_cartridges
  end
end
