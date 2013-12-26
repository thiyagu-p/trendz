require 'spec_helper'

describe WatchlistsController do

  def valid_attributes
    stock = Stock.create
    {name: 'a', stock_ids: [stock.id]}
  end

  describe "GET index" do
    it "assigns all watchlists as @watchlists" do
      watchlist = Watchlist.create! valid_attributes
      get :index
      assigns(:watchlists).should eq([watchlist])
    end
  end

  describe "GET show" do
    it "assigns the requested watchlist as @watchlist" do
      watchlist = Watchlist.create! valid_attributes
      get :show, :id => watchlist.id.to_s
      assigns(:watchlist).should eq(watchlist)
    end
  end

  describe "GET new" do
    it "assigns a new watchlist as @watchlist" do
      get :new
      assigns(:watchlist).should be_a_new(Watchlist)
    end
  end

  describe "GET edit" do
    it "assigns the requested watchlist as @watchlist" do
      watchlist = Watchlist.create! valid_attributes
      get :edit, :id => watchlist.id.to_s
      assigns(:watchlist).should eq(watchlist)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Watchlist" do
        expect {
          post :create, :watchlist => valid_attributes
        }.to change(Watchlist, :count).by(1)
      end

      it "creates a new Watchlist with stock" do
        post :create, :watchlist => valid_attributes
        assigns(:watchlist).stocks.count.should == 1
      end

      it "assigns a newly created watchlist as @watchlist" do
        post :create, :watchlist => valid_attributes
        assigns(:watchlist).should be_a(Watchlist)
        assigns(:watchlist).should be_persisted
      end

      it "redirects to the created watchlist" do
        post :create, :watchlist => valid_attributes
        response.should redirect_to(Watchlist.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved watchlist as @watchlist" do
        Watchlist.any_instance.stubs(:save).returns(false)
        expect{post :create, :watchlist => {}}.to raise_error(ActionController::ParameterMissing)
      end

      it "re-renders the 'new' template" do
        Watchlist.any_instance.stubs(:save).returns(false)
        expect{post :create, :watchlist => {}}.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested watchlist" do
        watchlist = Watchlist.create! valid_attributes
        Watchlist.any_instance.expects(:update_attributes).with({'name' => '123'})
        put :update, :id => watchlist.id, :watchlist => {name: '123'}
      end

      it "updates the requested watchlist with stocks" do
        watchlist = Watchlist.create! valid_attributes
        stocks = [Stock.create, Stock.create]
        stock_ids = stocks.collect(&:id)
        put :update, :id => watchlist.id, :watchlist => {stock_ids: stock_ids}
        assigns(:watchlist).stocks.should eq(stocks)
      end

      it "assigns the requested watchlist as @watchlist" do
        watchlist = Watchlist.create! valid_attributes
        put :update, :id => watchlist.id, :watchlist => valid_attributes
        assigns(:watchlist).should eq(watchlist)
      end

      it "redirects to the watchlist" do
        watchlist = Watchlist.create! valid_attributes
        put :update, :id => watchlist.id, :watchlist => valid_attributes
        response.should redirect_to(watchlist)
      end
    end

    describe "with invalid params" do
      it "assigns the watchlist as @watchlist" do
        watchlist = Watchlist.create! valid_attributes
        Watchlist.any_instance.stubs(:save).returns(false)
        expect{put :update, :id => watchlist.id.to_s, :watchlist => {}}.to raise_error(ActionController::ParameterMissing)
        assigns(:watchlist).should eq(watchlist)
      end

      it "re-renders the 'edit' template" do
        watchlist = Watchlist.create! valid_attributes
        Watchlist.any_instance.stubs(:save).returns(false)
        expect{put :update, :id => watchlist.id.to_s, :watchlist => {}}.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested watchlist" do
      watchlist = Watchlist.create! valid_attributes
      expect {
        delete :destroy, :id => watchlist.id.to_s
      }.to change(Watchlist, :count).by(-1)
    end

    it "redirects to the watchlists list" do
      watchlist = Watchlist.create! valid_attributes
      delete :destroy, :id => watchlist.id.to_s
      response.should redirect_to(watchlists_url)
    end
  end

end
