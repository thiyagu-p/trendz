class StocksController < ApplicationController

  def index
    @stocks = Stock.order(:symbol)
   end

end
