class Photo < ActiveRecord::Base
  validates :image ,presence: true

  before_save :get_mass_center_pixel_count

  BLACK_PIXEL = '1'
  WHITE_PIXEL = '0'

  def get_mass_center_pixel_count
    self.black_count = 0
    self.x_center_mass = 0
    self.y_center_mass = 0
    # TODO make a block for the for and only insert the middle part
    matrix = image.split /\r?\n/
    matrix.each_with_index do |line,y|
      #   we will use the first line size as number of colums for uniformity, could be the size of every line
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
    #update final position of the center, black_count == numberof incidents
    self.x_center_mass /= black_count
    self.y_center_mass /= black_count
    #parse every moment and store them as string
  end


  def calculate_central_moments
    matrix = image.split /\r?\n/
    moments = [[0,0,0],[0,0,0],[0,0,0]]
    p = 0
    while p < 3 do
      q = 0
      while q < 3 do
        central_moment = 0
        matrix.each_with_index do |line,y|
          #   we will use the first line size as number of colums for uniformity, could be the size of every line
          x = 0
          while x < matrix[0].size do
            if line[x] == BLACK_PIXEL
              central_moment +=  ((x  - self.x_center_mass) ** p) * ((y  - self.y_center_mass) ** q)
            end
            x += 1
          end
        end
        moments[p][q] = central_moment
        q += 1
      end
      p += 1
    end
    moments
  end

  def  calculate_invariant_moments
    central_moments = calculate_central_moments
    invariant_moments = [[0,0,0],[0,0,0],[0,0,0]]
    p = 0
    while p < 3 do
      q = 0
      while q < 3 do
        invariant_moments[p][q] = central_moments[p][q] / (central_moments[0][0] ** ((p+q/2)+1))
        q += 1
      end
      p += 1
    end
    invariant_moments
  end

end
