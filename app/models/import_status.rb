class ImportStatus < ActiveRecord::Base
  attr_accessible :data_upto, :completed, :last_run, :source

  module Source
    BSE_BHAV = 'bse_bhav'
    BSE_STOCKMASTER = 'bse_stock_master'
    NSE_SYMBOL_CHANGE = 'nse_symbol_change'
    NSE_EQUITIES_BHAV = 'nse_equities_bhav'
    NSE_DERIVATIVES_BHAV = 'nse_derivatives_bhav'
    NSE_CORPORATE_ACTION = 'nse_corporate_action'
    NSE_CORPORATE_RESULT = 'nse_corporate_result'
    NSE_STOCK_MASTER = 'nse_stock_master'
    YAHOO_QUOTES = 'yahoo_quotes'
  end

  def self.completed(source)
    self.find_by_source(source).update_attributes!(last_run: Date.today, completed: true)
  end

  def self.completed_upto_today(source)
    self.find_by_source(source).update_attributes!(data_upto: Date.today, last_run: Date.today, completed: true)
  end

  def self.failed(source)
    self.find_by_source(source).update_attributes!(last_run: Date.today, completed: false)
  end
end
