Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
   root 'pages#home'
   resources :games
   post 'games/:id/add-players' => 'games#add_players', as: :add_players
   post 'games/:id/assign-targets' => 'games#assign_targets', as: :assign_targets
   post 'redirect-to-game' => 'pages#redirect', as: :redirect_to_game
   post 'games/:id/life-update' => 'games#life_update', as: :life
   get 'about' => 'pages#about', as: :about
   get 'games/:id/signup' => 'games#signup', as: :signup
   post 'games/:id/add-player' => 'games#add_player', as: :add_player
   get 'games/:id/create-alerts' => 'games#create_alerts', as: :create_alerts
   post 'games/:id/create-alerts' => 'games#send_alerts', as: :send_alerts

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
