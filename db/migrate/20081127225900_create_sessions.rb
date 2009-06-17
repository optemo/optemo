class CreateSessions < ActiveRecord::Migration
  def self.up
    #system "/usr/local/bin/rake db:properties"
    create_table :sessions do |t|
      t.timestamps
      t.primary_key :id
      t.string :ip
      t.integer :parent_id
      t.string :product_type
      t.string :brand, :default => "All Brands"
      t.boolean :filter
      (Camera::ContinuousFeatures | Printer::ContinuousFeatures).each do |f|
        min = f+'_min'
        max = f+'_max'
        t.float min.intern #, :default => f.min.to_i
        t.float max.intern #, :default => f.max.ceil
      end
    end
  end

  def self.down
    drop_table :sessions
  end
end
