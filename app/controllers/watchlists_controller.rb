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
    @watchlist = Watchlist.new(params[:watchlist])
      if @watchlist.save
        redirect_to(@watchlist, :notice => 'Watchlist was successfully created.')
      else
        render :action => "new"
      end
  end

  def update
    @watchlist = Watchlist.find(params[:id])
      if @watchlist.update_attributes(params[:watchlist])
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
end
