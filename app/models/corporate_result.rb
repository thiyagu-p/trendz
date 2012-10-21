class CorporateResult < ActiveRecord::Base

  def quarter_start
    quarter_end.beginning_of_quarter
  end
end
