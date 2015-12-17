class Photo < ActiveRecord::Base
  attr_accessor :photos
  validates :image ,presence: true
  validate :get_mass_center_pixel_count
  attr_accessor :points_x_perimeter
  attr_accessor :points_y_perimeter
  attr_accessor :perimeter_points
  attr_accessor :f8_strings
  attr_accessor :af8_strings
  @points_x_perimeter = []
  @points_y_perimeter = []
  @perimeter_points = []
  @f8_strings = []
  @af8_strings = []
  BLACK_PIXEL = '1'
  WHITE_PIXEL = '0'
  paginates_per 5
  AF8_MATRIX = [ [ 0, 1, 2, 3, 4, 5, 6, 7],
                 [ 7, 0, 1, 2, 3, 4, 5, 6],
                 [ 6, 7, 0, 1, 2, 3, 4, 5],
                 [ 5, 6, 7, 0, 1, 2, 3, 4],
                 [ 4, 5, 6, 7, 0, 1, 2, 3],
                 [ 3, 4, 5, 6, 7, 0, 1, 2],
                 [ 2, 3, 4, 5, 6, 7, 0, 1],
                 [ 1, 2, 3, 4, 5, 6, 7, 0]]

  # Calculate the center mas
  def get_mass_center_pixel_count
    # reset all variable to count again
    black_count = 0
    white_count = 0
    x_center_mass = 0
    y_center_mass = 0
    # TODO make a block for the for and only insert the middle part
    # we separate by newline so we get a array of strings
    matrix = image.split /\r?\n/
    # go for every element in this matrix of string
    matrix.each_with_index do |line,y|
      #   we will use the first line size as number of colums for uniformity, could be the size of every line
      # get every pixel in the curren line
      (0..matrix[0].size - 1).each do |x|
        if line[x] == BLACK_PIXEL
          black_count += 1
          x_center_mass += x
          y_center_mass += y
        elsif line[x] == WHITE_PIXEL
          white_count += 1
        # else RAISE EXEPTION OR VALIDATION ERROR invalid caracter added
        else
          errors.add(:image, "Caracter '#{line[x]}' no valido")
          return false
        end
      end
    end
    #update final position of the center, black_count == numberof incidents
    if black_count == 0
      # no black pixels added
      errors.add(:image, 'No agrego pixeles negros')
      return false
    end
      # calculate the y and x for the center mass
      x_center_mass /= black_count
      y_center_mass /= black_count
    #parse every moment and store them as string
    self.central_moments = calculate_central_moments.to_s
    self.invariant_moments = calculate_invariant_moments.to_s
    #
    self.black_count = black_count
    self.white_count = white_count
    self.x_center_mass = x_center_mass
    self.y_center_mass = y_center_mass
    calculate_hu_moments

    calculate_perimeter_tetrapixel
    true
  end


  def calculate_central_moments
    # we separate by newline so we get a array of strings
    matrix = image.split /\r?\n/
    # initialize all momments in 0
    moments = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    (0..3).each do |p|
      (0..3 ).each do |q|
        central_moment = 0
        matrix.each_with_index do |line,y|
          #   we will use the first line size as number of colums for uniformity, could be the size of every line
          (0..matrix[0].size - 1).each do |x|
            central_moment += ((x - self.x_center_mass.to_i) ** p) * ((y - self.y_center_mass.to_i) ** q) if line[x] == BLACK_PIXEL
          end
        end
        moments[p][q] = central_moment
      end
    end
    # return the array of moments of size  4x4
    moments
  end

  def  calculate_invariant_moments
    # get the central moments before
    central_moments = calculate_central_moments
    # initialize all momments in 0
    invariant_moments = [[0,0,0,0],[0,0,0],[0,0,0],[0,0,0,0]]
    (0..3).each do |p|
      (0..3).each do |q|
        invariant_moments[p][q] = central_moments[p][q] / (central_moments[0][0] ** ((p+q/2)+1))
      end
    end
    invariant_moments
  end

  # the total pixels is the sum of black and white
  def total_pixels
    self.white_count.to_i + self.black_count.to_i
  end

  # calculate the edges
  def get_edges
    ((4 * black_count.to_i) + self.perimeter.to_i) / 2
  end

  # calculate the vertex
  def get_vertex
    perimeter.to_i + tetrapixel.to_i
  end

  def get_contact_perimeter
    ((4 * black_count.to_i) - perimeter.to_i) / 2
  end

  # we use the formula to get the numer of holes in the images
  def get_holes
    (((2 * get_contact_perimeter.to_i) - perimeter.to_i) / 4) + 1 - tetrapixel.to_i
  end

  def get_euler
    get_vertex.to_i - get_edges.to_i  + black_count.to_i
  end


  def get_f8_strings
    @f8_strings = []
    perimeter  = sorted_perimeter
    (0...perimeter.size - 1).each do |index|
      x_value = perimeter[index][:x] - perimeter[index + 1][:x]
      y_value = perimeter[index][:y] - perimeter[index + 1][:y]
      @f8_strings << 0 if x_value == - 1 and y_value == 0
      @f8_strings << 1 if x_value == - 1 and y_value == - 1
      @f8_strings << 2 if x_value == 0 and y_value == - 1
      @f8_strings << 3 if x_value == 1 and y_value == - 1
      @f8_strings << 4 if x_value == 1 and y_value == 0
      @f8_strings << 5 if x_value == 1 and y_value == 1
      @f8_strings << 6 if x_value == 0 and y_value == 1
      @f8_strings << 7 if x_value == -1 and y_value == 1
    end
    @f8_strings
  end

  def get_af8_strings
    @af8_strings = []
    # if haven been calculated uses it if no generate
    get_f8_strings if @f8_strings.nil?
    (0...@f8_strings.size - 1).each do |index|
      @af8_strings << AF8_MATRIX[@f8_strings[index]][@f8_strings[index + 1]]
    end
    @af8_strings
  end



  # get an array of ids of images to merge
  def self.merge_images(ids)
    y_size  = x_size =position= 0
    photos = []
    # here we get the size of x and y of the bigger images
    ids.each_with_index do |id,index|
      next if id.blank?
      photo = Photo.find id
      photos << photo
      matrix = photo.image.split /\r?\n/
      if matrix.size >= y_size
        y_size = matrix.size
        position = index
      end
      if matrix[0].size >= x_size
        x_size = matrix[0].size
        position = index
      end
    end
    # generate a new image in white with the bigger sizes
    # photo = Photo.new
    photo = Photo.new image: photos[position].image
    photo_image = photo.image.split /\r?\n/
    photos.each do |add_photo|
      new_x = photos[position].x_center_mass.to_i - add_photo.x_center_mass.to_i
      new_y = photos[position].y_center_mass.to_i - add_photo.y_center_mass.to_i
      # matrix = add_photo.image.split /\r?\n/
      matrix = add_white_pixels new_x,new_y,add_photo
      matrix.each_with_index do |line,y|
        (0..matrix[0].size - 1).each do |x|
          # we get the point tha we are going to move the image so it fit the new center mass
          # we get the center mass of the new image and align the other center masses to that one
            photo_image[y][x] = matrix[y][x] if matrix[y][x] == BLACK_PIXEL
        end
      end
    end
    # add the new line to every column
    photo.image = photo_image.join "\r\n"
    photo.save

    photo
  end

  def sorted_perimeter
    # if haven been calculated uses it if no generate
    get_perimeter if @perimeter_points.nil?
    @perimeter_points.sort!{|a,b| Math.atan2(a[:y] - self.y_center_mass.to_i,a[:x] - self.x_center_mass.to_i ) <=>  Math.atan2(b[:y] - self.y_center_mass.to_f,b[:x] - self.x_center_mass.to_f )}
    @perimeter_points
  end

  # add columns and rows depending in the number of element we want to add
  def self.add_white_pixels(new_x,new_y,add_photo)
    matrix = add_photo.image.split /\r?\n/
    # go for every element in this matrix of string
    matrix.each do |line|
      if new_x < 0
        line << WHITE_PIXEL * (new_x * -1)
      else
        line.prepend WHITE_PIXEL * new_x
      end

    end
    if new_y <  0
      (new_y * -1).times do
        matrix << WHITE_PIXEL * matrix[0].size
      end
    else
      new_y.times do
        matrix.unshift WHITE_PIXEL * matrix[0].size
      end
    end
    matrix

  end


  def add_perimeter_point(x,y)
    @perimeter_points << {x: x,y: y}
    @points_x_perimeter << x
    @points_y_perimeter << y
  end

  def get_perimeter_recursive(x,y,matrix)
    # if we get a pixel out of bound we added to the perimeter array
    if y + 1 >= matrix.size or x + 1 >= matrix[0].size or y - 1 < 0 or x - 1 < 0
      add_perimeter_point x,y
      return
    end
    # if the pixel has a neiborhood white pixel then we add this point to the array
    if matrix[y + 1][x] == WHITE_PIXEL or matrix[y - 1][x] == WHITE_PIXEL or matrix[y - 1][x  - 1] == WHITE_PIXEL or matrix[y + 1][x  - 1] == WHITE_PIXEL or matrix[y - 1][x  + 1] == WHITE_PIXEL or matrix[y][x  + 1] == WHITE_PIXEL or matrix[y][x  - 1] == WHITE_PIXEL
      add_perimeter_point x,y
    end
  end


  def get_perimeter
    matrix = image.split /\r?\n/
    # go for every element in this matrix of string
    @points_x_perimeter = []
    @points_y_perimeter = []
    @perimeter_points = []
    matrix.each_with_index do |line,y|
      #   we will use the first line size as number of colums for uniformity, could be the size of every line
      # get every pixel in the curren line
      (0..matrix[0].size - 1).each do |x|
        if line[x] == BLACK_PIXEL
          get_perimeter_recursive x,y,matrix
        end
      end
    end
    @perimeter_points
  end




  def self.generate_blank_image(y,x)
    new_image = ''
    (0..y - 1).each_with_index do |_,cy|
      (0..x - 1).each_with_index do |_,cx|
        if y / 2 == cy and x / 2 == cx
          new_image << BLACK_PIXEL
        else
          new_image << WHITE_PIXEL
        end
      end
      new_image << "\r\n"
    end
    # new_image[(new_image.size ) / 2]  = BLACK_PIXEL
    new_image
  end

  def calculate_perimeter_tetrapixel
    perimeter = 0
    tetrapixel = 0
    matrix = image.split /\r?\n/
    matrix.each_with_index do |line,y|
      break if y == matrix.size - 1
      #   we will use the first line size as number of colums for uniformity, could be the size of every line
      (0..matrix[0].size - 1).each do |x|
        if matrix[y][x] == BLACK_PIXEL
          perimeter += 1 if matrix[y][x + 1] == WHITE_PIXEL
          perimeter += 1 if matrix[y + 1][x ] == WHITE_PIXEL
          perimeter += 1 if matrix[y][x - 1] == WHITE_PIXEL and x - 1 > 0
          perimeter += 1 if matrix[y - 1][x ] == WHITE_PIXEL and y + 1 > 0
          tetrapixel += 1 if matrix[y + 1][x] == BLACK_PIXEL and matrix[y][x + 1] == BLACK_PIXEL and matrix[y + 1][x + 1] == BLACK_PIXEL
        end
      end
    end
    self.tetrapixel = tetrapixel
    self.perimeter = perimeter
  end

  # we use the formulas to get the HU moments
  def calculate_hu_moments
    # calculate the central moments
    central_moments = calculate_central_moments
    self.first_moment_HU = (central_moments[2][0] + central_moments[0][2])
    self.second_moment_HU = ((central_moments[2][0] - central_moments[0][2]) ** 2) + (4 * (central_moments[1][1] ** 2))
    self.third_moment_HU = ((central_moments[3][0] - (3 * central_moments[1][2])) ** 2) + ((((3 * central_moments[2][1]) - central_moments[0][3])) ** 2)

  end


  # generate a new photo only with the perimeter of the image in black pixels
  def generate_perimeter_image
    matrix = image.split /\r?\n/
    matrix  = Photo.generate_blank_image matrix.size,matrix[0].size
    matrix = matrix.split /\r?\n/
    get_perimeter
    (0..@points_y_perimeter.size - 1).each do |index|
      matrix[@points_y_perimeter[index]][@points_x_perimeter[index]] = BLACK_PIXEL
    end
    Photo.create image: matrix.join( "\r\n")
  end


end
