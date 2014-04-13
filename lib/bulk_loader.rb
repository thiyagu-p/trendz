class BulkLoader

  def load_corp_actions
    symbol_changes = import_symbol_changes
    import_corporate_actions symbol_changes
  end

  def load_transaction
    clean_portfolio
    symbol_changes = import_symbol_changes
    save_transactions_with_corporate_actions symbol_changes
  end

  private

  def save_transactions_with_corporate_actions symbol_changes
    open('data/transaction_history.csv').readlines.each do |line|
      handle_transaction(line, symbol_changes)
    end
    EquityTransaction.order('date asc, type asc').to_a.each do |transaction|
      Equity::Trader.handle_new_transaction(transaction)
    end

    EquityHolding.joins(equity_transaction: :stock).select('distinct stocks.*').to_a.each do |stock|
      FaceValueAction.where("stock_id = #{stock.id} and not applied").order('ex_date').each { |action| action.apply_on_portfolio }
      BonusAction.where("stock_id = #{stock.id} and not applied").order('ex_date').each { |action| action.apply_on_portfolio }
    end

  end

  def handle_transaction(line, symbol_changes)
    date_str, symbol, action, quantity, price, brokerage, portfolio_name, trading_account_name, day_trading = line.split(',')
    date = Date.parse(date_str)
    symbol = symbol_changes[symbol] unless symbol_changes[symbol].nil?
    stock = Stock.find_or_initialize_by(symbol: symbol)
    if stock.new_record?
      stock.update_attributes face_value: 10, nse_active: false, is_equity: true
    end

    portfolio = Portfolio.find_or_create_by(name: portfolio_name)
    tranding_account = TradingAccount.find_or_create_by(name: trading_account_name)
    transaction = action == 'Sell' ? EquitySell.new : EquityBuy.new
    transaction.update_attributes! stock: stock, date: date, quantity: quantity, price: price, brokerage: brokerage,
                                   delivery: (day_trading.nil? || day_trading.strip != 'DT'), portfolio: portfolio, trading_account: tranding_account
  end

  def import_corporate_actions symbol_changes
    open('data/Log_CompanyAction.log').readlines.each do |line|
      date_str, symbol, dsb_value, base, action, is_percentage, skipped = line.split(',')
      symbol = symbol_changes[symbol] unless symbol_changes[symbol].nil?
      stock = Stock.find_or_initialize_by(symbol: symbol)
      if stock.new_record?
        stock.update_attributes face_value: 10, nse_active: false, is_equity: true
      end
      if action == 'Divident'
        dividend = DividendAction.find_or_initialize_by(stock_id: stock.id, ex_date: date_str)
        if dividend.new_record?
          if is_percentage == 'true'
            dividend.update_attributes! percentage: dsb_value
          else
            dividend.update_attributes! value: dsb_value
          end
        end
      elsif action == 'Bonus'
        bonus = BonusAction.find_or_initialize_by(stock_id: stock.id, ex_date: date_str)
        bonus.update_attributes! holding_qty: base, bonus_qty: dsb_value if bonus.new_record?
      elsif action == 'Split'
        split = FaceValueAction.find_or_initialize_by(stock_id: stock.id, ex_date: date_str)
        split.update_attributes! from: base, to: dsb_value if split.new_record?
      else
        p "Error in input file - #{line}"
      end
    end
  end

  def clean_portfolio
    BonusTransaction.delete_all
    FaceValueTransaction.delete_all
    DividendTransaction.delete_all
    EquityHolding.delete_all
    EquityTrade.delete_all
    EquityTransaction.delete_all
  end

  def import_symbol_changes
    symbol_chnages_by_date = Importer::Nse::SymbolChange.new.import_data
    symbol_chnages_by_date.inject({}) { |hash, h| hash[h[:symbol]] = h[:new_symbol]; hash }
  end

end