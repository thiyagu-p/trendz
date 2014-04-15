class HomeController < ApplicationController

  def index
    @dividend_actions = DividendAction.future_dividends_with_current_percentage
    @bonus_actions = BonusAction.where("ex_date >= ?", Date.today).order(:ex_date)
    @face_value_actions = FaceValueAction.where("ex_date >= ?", Date.today).order(:ex_date)
    @action_errors = CorporateActionError.where("ex_date >= ? and not is_ignored", Date.today).order(:ex_date)
    @consolidated_holdings = consolidate_holding EquityHolding.joins(equity_transaction: :portfolio).where("portfolios.name = 'Thiyagu'").all
    beginning_of_year = Date.today.beginning_of_year
    beginning_of_year -= 365 if Date.today.month == 1
    @year_beginning = EqQuote.where("date >= ?", beginning_of_year).minimum(:date)
    last_10_days = EqQuote.select('distinct date').limit(10).order('date desc')
    @best_performers = EqQuote.find_best_performers(last_10_days.last.date, last_10_days.first.date, 20)
  end

  private

  def consolidate_holding(holdings)
    holdings = holdings.group_by { |h| h.equity_transaction.stock }
    hash = {}
    today = Date.today
    holdings.each_pair do |stock, holding_list|
      tot_qty = tot_cost = avg_days = 0
      holding_list.each do |holding|
        tot_qty += holding.quantity
        tot_cost += holding.quantity * holding.equity_transaction.price
        avg_days += today - holding.equity_transaction.date
      end
      hash[stock] = {
          quantity: tot_qty,
          average_cost: (tot_cost / tot_qty).round(2),
          average_days: (avg_days / holding_list.size).round(0)
      }
    end
    hash
  end
end
