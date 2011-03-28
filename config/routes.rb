Site::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  resources :compare, :only => [:index, :create], :as => "searches"
  resources :surveys, :only => :new
  match "surveys/create" => "surveys#create", :as => "surveys" #This should be cleaned up to a POST instead of a GET in JS
  match "comparison/:id" => "direct_comparison#index" #This should be cleaned up to a POST instead of a GET in JS
  match "product/:name/:id" => "compare#show", :as => "product"
  match "similar/:id" => "compare#sim", :id => /\d+/, :as => "cluster"
  match "extended" => "compare#extended"
  match "filtering" => "compare#filtering"
  match "groupby/:feat" => "compare#groupby"
  match "zoomout" => "compare#zoomout"
  match "sitemap" => "compare#sitemap"
  root :to => "compare#index"
end
