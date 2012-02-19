require "spec_helper"

describe WatchlistsController do
  describe "routing" do

    it "routes to #index" do
      get("/watchlists").should route_to("watchlists#index")
    end

    it "routes to #new" do
      get("/watchlists/new").should route_to("watchlists#new")
    end

    it "routes to #show" do
      get("/watchlists/1").should route_to("watchlists#show", :id => "1")
    end

    it "routes to #edit" do
      get("/watchlists/1/edit").should route_to("watchlists#edit", :id => "1")
    end

    it "routes to #create" do
      post("/watchlists").should route_to("watchlists#create")
    end

    it "routes to #update" do
      put("/watchlists/1").should route_to("watchlists#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/watchlists/1").should route_to("watchlists#destroy", :id => "1")
    end

  end
end
