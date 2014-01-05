require "spec_helper"

describe Stock do

  it "should give latest quote" do
    stock = Stock.create
    first = EqQuote.create(stock: stock, date: Date.parse('01/01/2012'))
    latest = EqQuote.create(stock: stock, date: Date.parse('05/01/2012'))
    second = EqQuote.create(stock: stock, date: Date.parse('03/01/2012'))

    stock.latest_quote.should == latest
  end

  describe :face_value_on do
    it 'should calculate face value on date' do
      stock = Stock.create(face_value: 5)
      FaceValueAction.create!(stock: stock, ex_date: Date.today - 1, from: 10, to: 5)
      stock.face_value_on(Date.today - 2).should == 10
    end
    it 'should ignore future face value changes' do
      stock = Stock.create(face_value: 5)
      FaceValueAction.create!(stock: stock, ex_date: Date.today + 1, from: 10, to: 5)
      stock.face_value_on(Date.today - 2).should == 5
    end
    it 'should handle stock without any face value changes' do
      stock = Stock.create(face_value: 5)
      stock.face_value_on(Date.today - 2).should == 5
    end
    it 'should handle multiple face value changes' do
      stock = Stock.create(face_value: 5)
      FaceValueAction.create!(stock: stock, ex_date: Date.today - 3, from: 6, to: 5)
      FaceValueAction.create!(stock: stock, ex_date: Date.today - 2, from: 5, to: 1)
      FaceValueAction.create!(stock: stock, ex_date: Date.today - 1, from: 1, to: 5)
      stock.face_value_on(Date.today - 10).should == 6
      stock.face_value_on(Date.today - 4).should == 6
      stock.face_value_on(Date.today - 3).should == 5
      stock.face_value_on(Date.today - 2).should == 1
      stock.face_value_on(Date.today - 1).should == 5
      stock.face_value_on(Date.today).should == 5
    end
  end
end