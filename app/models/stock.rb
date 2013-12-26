class Stock < ActiveRecord::Base

  module NseSeries
    EQUITY = 'EQ'
    INDEX = 'I'
  end

  has_many :fo_quotes
  has_many :eq_quotes

  has_one :latest_quote, -> {order('date desc')}, class_name: 'EqQuote'

  def performance
    StockPerformance.new(self)
  end

  def face_value_on(date)
    face_value_action = FaceValueAction.where("stock_id = #{self.id}").where("ex_date > ?", date).order('ex_date asc').first
    face_value_action.nil? ? face_value : face_value_action.from
  end
end
