class WatchlistsController < ApplicationController

  def index
    @watchlists = Watchlist.all
  end

  def show
    @watchlist = Watchlist.find(params[:id])
  end

  def new
    @watchlist = Watchlist.new
  end

  def edit
    @watchlist = Watchlist.find(params[:id])
    @stocks = Stock.all
  end

  def create
    @watchlist = Watchlist.new(watchlist_params)
    @watchlist.stock_ids = params[:watchlist][:stock_ids]
      if @watchlist.save
        redirect_to(@watchlist, :notice => 'Watchlist was successfully created.')
      else
        render :action => "new"
      end
  end

  def update
    @watchlist = Watchlist.find(params[:id])
    @watchlist.stock_ids = params[:watchlist][:stock_ids]
      if @watchlist.update_attributes(watchlist_params)
        redirect_to(@watchlist, :notice => 'Watchlist was successfully updated.')
      else
        render :action => "edit"
      end
  end

  def destroy
    @watchlist = Watchlist.find(params[:id])
    @watchlist.destroy
    redirect_to action: :index
  end

  private
  def watchlist_params
    params.require(:watchlist).permit(:name);
  end
end
