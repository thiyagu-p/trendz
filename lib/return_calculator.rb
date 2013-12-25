class ReturnCalculator

  def recalculate
    ActiveRecord::Base.connection.execute("drop table if exists returns")
    dates = EqQuote.where('date >= ?', Date.today.beginning_of_year).select('min(date) as min, max(date) as max').first
    ActiveRecord::Base.connection.execute("select st.stock_id, round((en.close - st.close)/st.close * 100) as ytw into returns from eq_quotes st join eq_quotes en on st.stock_id = en.stock_id and st.date = '#{dates.min}' and en.date = '#{dates.max}'")

    weeks = ActiveRecord::Base.connection.execute("select week, min(date) as min, max(date) as max from (select distinct date, EXTRACT(WEEK FROM date) as week from eq_quotes where date >= '#{dates.min}' and date <= '#{dates.max}') as foo group by week order by week")
    weeks.each do |week|
      ActiveRecord::Base.connection.execute("alter table returns add column w#{week['week']} numeric")
      stmt = "update returns set w#{week['week']} = calc.diff from (select st.stock_id, round((en.close - st.close)/st.close * 100) as diff from eq_quotes st join eq_quotes en on st.stock_id = en.stock_id and st.date = '#{week['min']}' and en.date = '#{week['max']}') as calc where calc.stock_id = returns.stock_id"
      ActiveRecord::Base.connection.execute(stmt)
    end

    max_date = Date.parse dates["max"]
    [10, 20, 50, 200, 365].each do |days|
      ActiveRecord::Base.connection.execute("alter table returns add column d#{days} numeric")
      st = ActiveRecord::Base.connection.execute("select min(date) as min from eq_quotes where date >= '#{max_date - days}'").first
      stmt = "update returns set d#{days} = calc.diff from (select st.stock_id, round((en.close - st.close)/st.close * 100) as diff from eq_quotes st join eq_quotes en on st.stock_id = en.stock_id and st.date = '#{st['min']}' and en.date = '#{max_date}') as calc where calc.stock_id = returns.stock_id"
      ActiveRecord::Base.connection.execute(stmt)
    end
  end
end