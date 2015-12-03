json.array!(@photos) do |photo|
  json.extract! photo, :id, :image, :x_center_mass, :y_center_mass, :white_count, :black_count
  json.url photo_url(photo, format: :json)
end
