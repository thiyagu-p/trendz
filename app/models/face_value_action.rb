class FaceValueAction < ActiveRecord::Base
  belongs_to :stock

  def apply
    return if applied?
    self.transaction do
      apply_on_portfolio
      apply_on_eq_quotes
      self.applied = true
      save!
    end
  end

  private

  def apply_on_eq_quotes
    EqQuote.apply_factor self.stock, conversion_ration, ex_date
  end

  def conversion_ration
    (to.to_f/from.to_f).round(2)
  end

  def apply_on_portfolio
    TradingAccount.all.each do |trading_account|
      Portfolio.all.each do |portfolio|
        record_date = self.ex_date - 1
        holdings = EquityBuy.find_holdings_on self.stock, record_date, trading_account, portfolio
        holdings.each do |transaction|
          transaction.apply_face_value_change(conversion_ration, record_date)
        end
      end
    end
  end


end
