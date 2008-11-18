class CreateWelcomes < ActiveRecord::Migration
  def self.up
    create_table :welcomes do |t|
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :welcomes
  end
end
