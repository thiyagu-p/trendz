class HomeController < ApplicationController

  def index
    future_corporate_actions = CorporateAction.includes(:stock).where("ex_date >= ?", Date.today).order(:ex_date)
    @corporate_actions = filter_ignore(future_corporate_actions)
    @equity_holding = EquityHolding.all
  end

  private
  def filter_ignore corporate_actions
    latest_quote_date = EqQuote.maximum(:date)
    eq_quotes = EqQuote.find_all_by_date_and_stock_id(latest_quote_date, corporate_actions.collect{|action| action.stock.id})
    eq_quotes_hash = eq_quotes.inject({}) {|hash, quote| hash[quote.stock_id] = quote; hash}
    corporate_actions.select!{ |corporate_action| eq_quotes_hash[corporate_action.stock_id]}

    corporate_actions.each do |corporate_action|
      actions = JSON.parse(corporate_action.parsed_data)
      actions.reject! {|action| action["type"] == "ignore" }
      actions.each do |action|
        action["current_percentage"] = (action["value"].to_i / eq_quotes_hash[corporate_action.stock_id].close * 100) if action["type"] == "divident" && action["value"]
      end
      corporate_action.parsed_data = actions
    end
    corporate_actions.reject!{ |corporate_action| corporate_action.parsed_data == []}
  end
end
