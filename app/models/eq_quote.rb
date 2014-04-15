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

  def self.find_best_performers(start_date, end_date, limit)
    EqQuote.find_by_sql("select st.stock_id, round((en.close - st.close)/st.close*100) perf from eq_quotes st join eq_quotes en on st.date = '#{start_date}' and st.stock_id = en.stock_id and en.date = '#{end_date}' join stocks s on s.id = st.stock_id and s.bse_group in ('A') order by 2 desc limit #{limit}")
  end
end
