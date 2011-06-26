class MovingAverageCalculator

  def self.update(date, stock)
    set_moving_average(stock, date, 10)
    set_moving_average(stock, date, 50)
    set_moving_average(stock, date, 200)
  end

  private

  def self.set_moving_average(stock, date, days)
    ActiveRecord::Base.connection.execute("update eq_quotes set mov_avg_#{days}d = (select avg(close) from (select close from eq_quotes where stock_id=#{stock.id} and date <= '#{date}' order by date desc limit #{days})  as t ) where date = '#{date}' and stock_id=#{stock.id}")
  end
end