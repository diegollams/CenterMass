class Photo < ActiveRecord::Base
  validates :image ,presence: true

  before_save :get_mass_center_pixel_count

  BLACK_PIXEL = '1'
  WHITE_PIXEL = '0'

  def get_mass_center_pixel_count
    self.black_count = 0
    self.x_center_mass = 0
    self.y_center_mass = 0
    matrix = image.split /\r?\n/
    matrix.each_with_index do |line,y|
      #   we will use the first line size as number of colums for uniformity could be the size of every line
      x = 0
      while x < matrix[0].size do
        if line[x] == BLACK_PIXEL
          self.black_count += 1
          self.x_center_mass += x
          self.y_center_mass += y
        elsif line[x] == WHITE_PIXEL
          self.white_count += 1
        # else RAISE EXEPTION OR VALIDATION ERROR
        end
        x += 1
      end
    end
    self.x_center_mass /= black_count
    self.y_center_mass /= black_count
  end

end
