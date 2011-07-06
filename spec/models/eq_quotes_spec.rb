require 'spec/spec_helper.rb'

describe "EqQuotes" do

  it "should not exists without stock" do
    lambda { EqQuote.create!(:stock_id => 0) }.should raise_exception(ActiveRecord::InvalidForeignKey)
    EqQuote.find_by_stock_id(0).should be_nil
  end
end