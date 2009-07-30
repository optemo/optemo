class CreateTigerOfferings < ActiveRecord::Migration
  def self.up
    create_table :tiger_offerings do |t|

      # Auto filled in
      t.timestamps
      t.primary_key :id
      
      # ID
      t.text     :tigerurl
      
      # MUST FILL IN:
      t.integer  :tiger_printer_id
      t.integer  :priceint
      t.string   :pricestr
      t.boolean  :toolow
      t.boolean  :stock
      t.string   :region
      t.text     :url 
    end
  end

  def self.down
    drop_table :tiger_offerings
  end
end
