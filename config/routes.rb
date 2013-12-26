Trendz::Application.routes.draw do
  root :to => 'home#index'

  resources :charts, only: [:index, :show]
  resources :corporate_actions, only: [:index, :show]

  resources :stocks, :only => [:index] do
    resource :eq_quote, :only => [:show]
    resource :fo_quote, :only => [:show]
  end

  resources :watchlists

  resources :equity_transactions

  get 'status' => 'status#show'
  get 'fo_charts' => 'fo_charts#index'
  get 'fo_charts/data/:symbol' => 'fo_charts#show_data'
  get 'fo_charts/ratio/:symbol' => 'fo_charts#show_ratio'
  get 'market_activity' => 'market_activity#chart'
end
