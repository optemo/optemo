class CreateLaptopBoostexterCombinedRules < ActiveRecord::Migration
  def self.up
    create_table :laptop_boostexter_combined_rules do |t|
      t.string :fieldname
      t.float :weight
      t.integer :cluster_id
      t.integer :version
      t.text :yaml_repr

      t.timestamps
      t.string :rule_type
    end
    add_index :laptop_boostexter_combined_rules, :fieldname
    add_index :laptop_boostexter_combined_rules, :cluster_id
    add_index :laptop_boostexter_combined_rules, :version
  end

  def self.down
    drop_table :laptop_boostexter_combined_rules
  end
end
