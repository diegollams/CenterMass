class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.text :image
      t.integer :x_center_mass,default: 0
      t.integer :y_center_mass,default: 0
      t.integer :white_count,default: 0
      t.integer :black_count,default: 0
      t.integer :first_moment_HU,default: 0
      t.integer :second_moment_HU,default: 0
      t.integer :third_moment_HU,default: 0
      t.integer :perimeter,default: 0
      t.integer :tetrapixel,default: 0
      t.string :central_moments
      t.string :invariant_moments
      t.timestamps null: false
    end
  end
end
