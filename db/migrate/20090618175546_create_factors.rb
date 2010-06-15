class CreateFactors < ActiveRecord::Migration
  def self.up
    create_table :factors do |t|
      t.timestamps
      t.primary_key :id
      t.string :product_type      
      t.integer :product_id
      t.string :cont_var
      t.float :value      
    end
  end

  def self.down
    drop_table :factors
  end
end