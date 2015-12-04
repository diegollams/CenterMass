module PhotosHelper

  def display_text_with_format(text)
    text.gsub /\r?\n/, '<br>'
  end

  def display_image matrix, size = 10
    matrix = matrix.split /\r?\n/
    size_style = "width: #{size}px; height: #{size}px;"
    content_tag :table, class: "image-binary" do
      matrix.each_with_index do |line,y|
        concat(content_tag(:tr) do
        #   we will use the first line size as number of colums for uniformity, could be the size of every line
          (0..matrix[0].size - 1).each do |x|
            color = line[x] == Photo::BLACK_PIXEL ? 'black' : 'white'
            concat content_tag(:td, nil, class: color, style: size_style)
          end
        end)
      end
    end
  end
end
