class CreateFactors < ActiveRecord::Migration
  def self.up
    create_table :factors do |t|
      t.timestamps
      t.primary_key :id
      t.string :product_type      
      t.integer :product_id
      (Camera::ContinuousFeatures | Printer::ContinuousFeatures | Flooring::ContinuousFeatures).each do |f|
        t.float f
      end
    end
  end

  def self.down
    drop_table :factors
  end
end