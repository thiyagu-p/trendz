class BulkLoader

  def load
    clean_portfolio
    symbol_changes = import_symbol_changes
    import_corporate_actions symbol_changes
    save_transactions_with_corporate_actions symbol_changes
  end

  private

  def save_transactions_with_corporate_actions symbol_changes
    open('data/Log_Transaction_a.log').readlines.each do |line|
      handle_transaction(line, symbol_changes)
    end
  end

  def handle_transaction(line, symbol_changes)
    date_str, symbol, action, quantity, price, brokerage, portfolio_name, trading_account_name, day_trading = line.split(',')
    date = Date.parse(date_str)
    symbol = symbol_changes[symbol] unless symbol_changes[symbol].nil?
    stock = Stock.find_or_create_by_symbol symbol
    if stock.nse_series.nil?
      stock.update_attributes face_value: 10, nse_active: false, nse_series: Stock::NseSeries::EQUITY
    end
    BonusAction.all(conditions: "stock_id = #{stock.id} and ex_date <= '#{date}' and not applied", order: 'ex_date').each { |bonus| bonus.apply }
    FaceValueAction.all(conditions: "stock_id = #{stock.id} and ex_date <= '#{date}' and not applied", order: 'ex_date').each { |face_value_action| face_value_action.apply }

    portfolio = Portfolio.find_or_create_by_name portfolio_name
    tranding_account = TradingAccount.find_or_create_by_name trading_account_name
    transaction = action == 'Sell' ? EquitySell.new : EquityBuy.new
    transaction.update_attributes! stock: stock, date: date, quantity: quantity, price: price, brokerage: brokerage,
                                   delivery: day_trading != 'DT', portfolio: portfolio, trading_account: tranding_account
  end

  def import_corporate_actions symbol_changes
    open('data/Log_CompanyAction_a.log').readlines.each do |line|
      date_str, symbol, dsb_value, base, action, is_percentage, skipped = line.split(',')
      symbol = symbol_changes[symbol] unless symbol_changes[symbol].nil?
      stock = Stock.find_or_create_by_symbol symbol
      if stock.nse_series.nil?
        stock.update_attributes face_value: 10, nse_active: false, nse_series: Stock::NseSeries::EQUITY
      end
      if action == 'Divident'
        dividend = DividendAction.find_or_initialize_by_stock_id_and_ex_date(stock.id, date_str)
        if dividend.new_record?
          percentage = is_percentage == 'true' ? dsb_value : dsb_value.to_f / 10.0
          dividend.update_attributes! percentage: percentage
        end
      end
      if action == 'Bonus'
        bonus = BonusAction.find_or_initialize_by_stock_id_and_ex_date(stock.id, date_str)
        bonus.update_attributes! holding_qty: base,  bonus_qty: dsb_value if bonus.new_record?
      end
      if action == 'Split'
        split = FaceValueAction.find_or_initialize_by_stock_id_and_ex_date(stock.id, date_str)
        split.update_attributes! from: base,  to: dsb_value if split.new_record?
      end
    end
  end

  def clean_portfolio
    EquityHolding.delete_all
    EquityTrade.delete_all
    EquityTransaction.delete_all
  end

  def import_symbol_changes
    symbol_chnages_by_date = Importer::Nse::SymbolChange.new.import_data
    symbol_chnages_by_date.inject({}) { |hash, h| hash[h[:symbol]] = h[:new_symbol]; hash }
  end

end