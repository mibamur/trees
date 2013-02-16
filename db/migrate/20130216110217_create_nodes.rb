class CreateNodes < ActiveRecord::Migration
  def up
    create_table :nodes do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
 
  def down
    drop_table :nodes
  end
end
