module PhotosHelper

  def display_text_with_format(text)
    text.gsub /\r?\n/, '<br>'
  end
end
