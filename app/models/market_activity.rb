class MarketActivity < ActiveRecord::Base

  def equity_fii
    fii_buy_equity - fii_sell_equity
  end

  def debit_fii
    fii_buy_debit - fii_sell_debit
  end

  def fo_index_fii
    return 0 unless fii_index_futures_buy
    fii_index_futures_buy - fii_index_futures_sell + fii_index_options_buy - fii_index_options_sell
  end

  def fo_stock_fii
    return 0 unless fii_stock_futures_buy
    fii_stock_futures_buy - fii_stock_futures_sell + fii_stock_options_buy - fii_stock_options_sell
  end

  def index_futures
    return 0 unless fii_index_futures_buy
    fii_index_futures_buy - fii_index_futures_sell
  end

  def index_options
    return 0 unless fii_index_futures_buy
    fii_index_options_buy - fii_index_options_sell
  end

end
