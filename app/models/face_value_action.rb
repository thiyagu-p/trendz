class FaceValueAction < ActiveRecord::Base
  belongs_to :stock

  def apply
    apply_on_portfolio
  end

  def conversion_ration
    (to.to_f/from.to_f).round(2)
  end
  
  private

  def apply_on_portfolio
    TradingAccount.all.each do |trading_account|
      Portfolio.all.each do |portfolio|
        record_date = self.ex_date - 1
        holdings = EquityBuy.find_holdings_on self.stock, record_date, trading_account, portfolio
        holdings.each do |transaction|
          transaction.apply_face_value_change(self.conversion_ration, record_date)
        end
      end
    end
  end


end
