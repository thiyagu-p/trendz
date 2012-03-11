class Stock < ActiveRecord::Base

  module Series
    EQUITY = 'e'
    INDEX = 'i'
  end

  has_many :fo_quotes
  has_many :eq_quotes

  has_one :latest_quote, class_name: 'EqQuote', order: 'date desc'

  def performance
    StockPerformance.new(self)
  end
end
