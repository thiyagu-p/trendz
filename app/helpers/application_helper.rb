module ApplicationHelper

  def display_returns(value)
    "<span class=\"#{value.to_f < 0 ? 'red' :'green'}\">#{number_to_percentage value.to_f, precision: 2}</span>"
  end

  def display_price(value)
    number_with_precision value, precision: 2
  end

  def display_stock_symbol(symbol)
    link_to symbol, (chart_path symbol)
  end
end
