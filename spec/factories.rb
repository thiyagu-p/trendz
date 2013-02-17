FactoryGirl.define do

  factory :stock do
    symbol 'MYSTOCK'
  end

  factory :fo_quote do
    close 10.1
    open_interest 15.2
  end

  factory :trading_account do
    name 'Account'
  end

  factory :portfolio do
    name 'Portfolio'
  end

  factory :equity_transaction, class: 'equity_transaction' do
    trading_account
    portfolio
    stock
    price 1
    quantity 1
    action 'buy'
    date Date.today
    delivery false
  end

  factory :equity_buy do
    trading_account
    portfolio
    stock
    price 1
    quantity 1
    date Date.today
    delivery false
  end

  factory :equity_sell do
    trading_account
    portfolio
    stock
    price 1
    quantity 1
    date Date.today
    delivery false
  end

  factory :equity_holding do
    association :equity_transaction, quantity: 10
    quantity 10
  end

end