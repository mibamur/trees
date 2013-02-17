Trees::Application.routes.draw do

  root to: 'nodes#index'

  resources :nodes, except: :index
  
end