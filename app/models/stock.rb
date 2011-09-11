class Stock < ActiveRecord::Base

  module Series
    EQUITY = 'e'
    INDEX = 'i'
  end

  has_many :fo_quotes
  has_many :eq_quotes
end
