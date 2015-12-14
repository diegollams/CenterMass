class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.text :image
      t.string :x_center_mass,default: 0
      t.string :y_center_mass,default: 0
      t.string :white_count,default: 0
      t.string :black_count,default: 0
      t.string :first_moment_HU,default: 0
      t.string :second_moment_HU,default: 0
      t.string :third_moment_HU,default: 0
      t.string :perimeter,default: 0
      t.string :tetrapixel,default: 0
      t.string :central_moments
      t.string :invariant_moments
      t.timestamps null: false
    end
  end
end
