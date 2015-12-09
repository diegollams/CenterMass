class Photo < ActiveRecord::Base
  attr_accessor :photos
  validates :image ,presence: true
  validate :get_mass_center_pixel_count

  BLACK_PIXEL = '1'
  WHITE_PIXEL = '0'

  def get_mass_center_pixel_count
    self.black_count = 0
    self.white_count = 0
    self.x_center_mass = 0
    self.y_center_mass = 0
    # TODO make a block for the for and only insert the middle part
    matrix = image.split /\r?\n/
    matrix.each_with_index do |line,y|
      #   we will use the first line size as number of colums for uniformity, could be the size of every line
      (0..matrix[0].size - 1).each do |x|
        if line[x] == BLACK_PIXEL
          self.black_count += 1
          self.x_center_mass += x
          self.y_center_mass += y
        elsif line[x] == WHITE_PIXEL
          self.white_count += 1
        # else RAISE EXEPTION OR VALIDATION ERROR
        else
          errors.add(:image, "Caracter '#{line[x]}' no valido")
          return false
        end
      end
    end
    #update final position of the center, black_count == numberof incidents
    if black_count == 0
      errors.add(:image, "No agrego pixeles negros")
      return false
    end
      self.x_center_mass /= black_count
      self.y_center_mass /= black_count
    #parse every moment and store them as string
    self.central_moments = calculate_central_moments.to_s
    self.invariant_moments = calculate_invariant_moments.to_s
    calculate_hu_moments
    calculate_perimeter_tetrapixel
    true
  end


  def calculate_central_moments
    matrix = image.split /\r?\n/
    moments = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    (0..3).each do |p|
      (0..3 ).each do |q|
        central_moment = 0
        matrix.each_with_index do |line,y|
          #   we will use the first line size as number of colums for uniformity, could be the size of every line
          (0..matrix[0].size - 1).each do |x|
            if line[x] == BLACK_PIXEL
              central_moment +=  ((x  - self.x_center_mass) ** p) * ((y  - self.y_center_mass) ** q)
            end
          end
        end
        moments[p][q] = central_moment
      end
    end
    moments
  end

  def  calculate_invariant_moments
    central_moments = calculate_central_moments
    invariant_moments = [[0,0,0],[0,0,0],[0,0,0]]
    (0..2).each do |p|
      (0..2).each do |q|
        invariant_moments[p][q] = central_moments[p][q] / (central_moments[0][0] ** ((p+q/2)+1))
      end
    end
    invariant_moments
  end

  def total_pixels
    self.white_count + self.black_count
  end

  def get_edges
    ((4 * black_count) + self.perimeter) / 2
  end

  def get_vertex
    perimeter + tetrapixel
  end

  def get_contact_perimeter
    ((4 * black_count) - perimeter) / 2
  end

  def get_holes
    (((2 * get_contact_perimeter) - perimeter) / 4) + 1 - tetrapixel
  end

  def get_euler
    get_vertex - get_edges  + black_count
  end



  def self.merge_images(ids)
    y_size  = x_size = 0
    photos = []
    ids.each do |id|
      next if id.blank?
      photo = Photo.find id
      photos << photo
      matrix = photo.image.split /\r?\n/
      if matrix.size >= y_size
        y_size = matrix.size
      end
      if matrix[0].size >= x_size
        x_size = matrix[0].size
      end
    end
    photo = Photo.new
    photo.image = Photo.generate_blank_image y_size,x_size
    photo.save
    photo_image = photo.image.split /\r?\n/
    photos.each do |add_photo|
      matrix = add_photo.image.split /\r?\n/
      matrix.each_with_index do |line,y|
        (0..matrix[0].size - 1).each do |x|
          new_x = photo.x_center_mass - add_photo.x_center_mass
          new_y = photo.y_center_mass - add_photo.y_center_mass
          if line[x] == BLACK_PIXEL
            photo_image[y + new_y][x +new_x]  = BLACK_PIXEL
          end
        end
      end
    end


    photo.image = photo_image.join "\r\n"
    photo.save

    photo
  end


  private
  def self.generate_blank_image(y,x)
    new_image = ''
    (0..y - 1).each do |p|
      (0..x - 1).each do |q|
          new_image << WHITE_PIXEL
      end
      new_image << "\r\n"
    end
    new_image[(new_image.size ) / 2]  = BLACK_PIXEL
    new_image
  end

  def calculate_perimeter_tetrapixel
    self.perimeter = 0
    self.tetrapixel = 0
    matrix = image.split /\r?\n/
    matrix.each_with_index do |line,y|
      break if y == matrix.size - 1
      #   we will use the first line size as number of colums for uniformity, could be the size of every line
      (0..matrix[0].size - 1).each do |x|
        if matrix[y][x] == BLACK_PIXEL
          self.perimeter += 1 if matrix[y][x + 1] == WHITE_PIXEL
          self.perimeter += 1 if matrix[y + 1][x ] == WHITE_PIXEL
          self.perimeter += 1 if matrix[y][x - 1] == WHITE_PIXEL and x - 1 > 0
          self.perimeter += 1 if matrix[y - 1][x ] == WHITE_PIXEL and y + 1 > 0
          self.tetrapixel += 1 if matrix[y + 1][x] == BLACK_PIXEL and matrix[y][x + 1] == BLACK_PIXEL and matrix[y + 1][x + 1] == BLACK_PIXEL
        end
      end
    end
  end


  def calculate_hu_moments
    central_moments = calculate_central_moments
    self.first_moment_HU = (central_moments[2][0] + central_moments[0][2])
    self.second_moment_HU = ((central_moments[2][0] - central_moments[0][2]) ** 2) + (4 * (central_moments[1][1] ** 2))
    self.third_moment_HU = ((central_moments[3][0] - (3 * central_moments[1][2])) ** 2) + ((((3 * central_moments[2][1]) - central_moments[0][3])) ** 2)

  end

end
