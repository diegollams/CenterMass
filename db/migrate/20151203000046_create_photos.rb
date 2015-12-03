class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.text :image
      t.integer :x_center_mass,default: 0
      t.integer :y_center_mass,default: 0
      t.integer :white_count,default: 0
      t.integer :black_count,default: 0
      t.float :central_moment,default: 0
      t.timestamps null: false
    end
  end
end
