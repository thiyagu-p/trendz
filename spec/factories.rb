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

  factory :buy_equity_transaction, parent: :equity_transaction do
    action 'buy'
  end

  factory :sell_equity_transaction, parent: :equity_transaction do
    action 'sell'
  end

  factory :equity_holding do
    association :equity_transaction, quantity: 10
    quantity 10
  end

  factory :corporate_action do
    stock
  end

  factory :corporate_action_divident, parent: :corporate_action do
    parsed_data [{type: :divident, divident: "1", value: "12"}].to_json
  end

  factory :corporate_action_ignore, parent: :corporate_action do
    parsed_data [{type: :ignore, data: "AGM"}].to_json
  end

  factory :corporate_action_bonus, parent: :corporate_action do
    ignore do
      holding 1
      bonus 2
    end
    parsed_data {[{type: :bonus, bonus: bonus, holding: holding}].to_json}
  end
end