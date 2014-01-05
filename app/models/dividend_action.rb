class DividendAction < ActiveRecord::Base
  belongs_to :stock

  attr_accessor :current_percentage

  def self.future_dividends_with_current_percentage
    actions_with_current_percentage
  end

  def apply
    return if applied?
    self.transaction do
      update_attribute(:percentage, calculate_percentage) if percentage.nil?
      buys = EquityBuy.where(stock_id: self.stock_id).where("date < '#{ex_date}'")
      buys.each do |buy|
        record_date = ex_date - 1
        holding_qty = buy.holding_qty_on(record_date)
        next if holding_qty <= 0 || DividendTransaction.find_by(equity_transaction_id: buy, dividend_action_id: self.id)
        total_dividend = current_value * holding_qty
        DividendTransaction.create!(equity_buy: buy, dividend_action: self, value: total_dividend)
      end
      update_attribute(:applied, true)
    end
  end

  def current_value
    percentage / 100 * stock.face_value
  end


  private

  def self.actions_with_current_percentage
    dividends = includes(:stock => :latest_quote)
    .where("ex_date >= ? and eq_quotes.date = ?", Date.today, EqQuote.maximum(:date))
    .order([:ex_date, 'stocks.symbol'])
    dividends.each do |dividend|
      dividend.current_percentage = (dividend.value || dividend.current_value) / dividend.stock.latest_quote.close * 100
    end
  end

  def calculate_percentage
    (self.value / stock.face_value_on(ex_date) * 100).round(2)
  end

end
