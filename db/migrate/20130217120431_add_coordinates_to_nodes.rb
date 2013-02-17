class AddCoordinatesToNodes < ActiveRecord::Migration
  def change
  	add_column :nodes, :x, :integer
  	add_column :nodes, :y, :integer
  end
end
