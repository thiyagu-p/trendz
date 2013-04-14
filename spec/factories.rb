FactoryGirl.define do

  factory :stock do
    symbol 'MYSTOCK'
  end

  factory :fo_quote do
    close 10.1
    open_interest 15.2
  end

  factory :eq_quote do
    stock
    date Date.today
    open 10
    high 20
    low 5
    close 12
    previous_close 8
    traded_quantity 1000
    mov_avg_10d 10
    mov_avg_50d 50
    mov_avg_200d 200
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

  factory :bonus_action do
    stock
    holding_qty 1
    bonus_qty 1
    applied false
    ex_date Date.today
  end

  factory :face_value_action do
    stock
    from 10
    to 5
    applied false
    ex_date Date.today
  end


end