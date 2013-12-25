class EqQuote < ActiveRecord::Base
  belongs_to :stock

  def self.apply_factor(stock, factor, ex_date)
    fields = [:open, :high, :low, :close, :previous_close, :traded_quantity, :mov_avg_10d, :mov_avg_50d, :mov_avg_200d].collect do |field|
      " #{field} = #{field} * #{factor}"
    end
    EqQuote.update_all("#{fields.join(',')} where stock_id = #{stock.id} and date < '#{ex_date}'")
    max_date = EqQuote.where("stock_id = #{stock.id} and date >= '#{ex_date}' and date <= '#{ex_date + 1.year}'").maximum(:date)
    (ex_date .. max_date).each { |date| MovingAverageCalculator.update(date, stock)}  if max_date
  end
end
