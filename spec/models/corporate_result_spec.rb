require 'spec_helper'

describe CorporateResult do

  it 'should return begning of the quarter' do

    CorporateResult.new(quarter_end: Date.parse('2012-09-30')).quarter_start.should == Date.parse('2012-07-01')
    CorporateResult.new(quarter_end: Date.parse('2012-06-30')).quarter_start.should == Date.parse('2012-04-01')
    CorporateResult.new(quarter_end: Date.parse('2012-03-31')).quarter_start.should == Date.parse('2012-01-01')
    CorporateResult.new(quarter_end: Date.parse('2012-12-31')).quarter_start.should == Date.parse('2012-10-01')
  end
end