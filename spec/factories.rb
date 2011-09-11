FactoryGirl.define do

  factory :stock do
    symbol 'MYSTOCK'
  end

  factory :fo_quote do
    close 10.1
    open_interest 15.2
  end
end