module PhotosHelper

  def display_text_with_format(text)
    text.gsub /\r?\n/, '<br>'
  end

  def display_image(matrix, size = 3, x_center, y_center)
    matrix = matrix.split /\r?\n/
    size_style = "width: #{size}px; height: #{size}px;"
    content_tag :table, class: 'image-binary' do
      matrix.each_with_index do |line, y|
        concat(content_tag(:tr) do
                 #   we will use the first line size as number of colums for uniformity, could be the size of every line
                 (0..matrix[0].size - 1).each_with_index do |x, x_index|
                   color = line[x] == Photo::BLACK_PIXEL ? 'black' : 'white'
                   color = 'green' if y == y_center.to_i and x_index == x_center.to_i
                   concat content_tag(:td, nil, class: color, style: size_style)
                 end
               end)
      end
    end
  end

  def merge_x_y(exes,eyes)
    content_tag :ul,class: 'list-inline' do
      exes.each_with_index do  |x,index |
        concat(content_tag(:li,class: '') do
                 "x= #{x}, y= #{eyes[index]} || "
               end)
      end
      concat(content_tag :br)
    end
  end
end
