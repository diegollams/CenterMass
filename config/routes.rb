Rails.application.routes.draw do
  get 'home/index'

  resources :photos do
    get 'strings'
    get 'center', on: :new
    post 'center', to: 'photos#center_post',on: :new,as: :center_photo_post
  end
  # match 'photos/center_post', :to => 'photos#center',
  #       :via => :post,
  #       :as => :center_photo_post
  root 'home#index'

end
