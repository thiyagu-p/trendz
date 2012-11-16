class CorporateAction < ActiveRecord::Base

  belongs_to :stock

  def actions
    JSON.parse(parsed_data)
  end

  def self.future_actions_with_current_percentage
    actions_with_current_percentage
  end

  private

  def self.actions_with_current_percentage
    corporate_actions = includes(:stock => :latest_quote)
    .where("ex_date >= ? and eq_quotes.date = ?" , Date.today, EqQuote.maximum(:date))
    .order([:ex_date, 'stocks.symbol'])
    corporate_actions.each do |corporate_action|
      actions = JSON.parse(corporate_action.parsed_data)
      actions.reject! { |action| action["type"] == "ignore" }
      actions.each do |action|
        action["current_percentage"] = (action["value"].to_i / corporate_action.stock.latest_quote.close * 100) if action["type"] == "divident" && action["value"]
      end
      corporate_action.parsed_data = actions
    end
    corporate_actions.reject!{ |corporate_action| corporate_action.parsed_data == []}
    corporate_actions
  end

end
