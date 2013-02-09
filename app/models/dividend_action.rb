class DividendAction < ActiveRecord::Base
  belongs_to :stock

  attr_accessor :current_percentage

  def self.future_dividends_with_current_percentage
    actions_with_current_percentage
  end

  private

  def self.actions_with_current_percentage
    dividends = includes(:stock => :latest_quote)
    .where("ex_date >= ? and eq_quotes.date = ?" , Date.today, EqQuote.maximum(:date))
    .order([:ex_date, 'stocks.symbol'])
    dividends.each do |dividend|
      dividend.current_percentage = dividend.percentage / 100 * dividend.stock.face_value / dividend.stock.latest_quote.close * 100
    end
  end

end
