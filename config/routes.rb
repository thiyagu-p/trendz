Trendz::Application.routes.draw do
  root :to => 'charts#index'

  resources :charts, only: [:index, :show]

  resources :stocks, :only => [:index] do
    resource :eqQuote, :only => [:show]
    resource :foQuote, :only => [:show]
  end

  resources :watchlists

  resources :equity_transactions

  match 'status' => 'status#show'
  match 'fo_charts' => 'fo_charts#index'
  match 'fo_charts/data/:symbol' => 'fo_charts#show_data'
  match 'fo_charts/ratio/:symbol' => 'fo_charts#show_ratio'
  match 'market_activity' => 'market_activity#chart'
end
